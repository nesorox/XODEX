package com.burzen.td

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

data class Enemy(var x: Float, var y: Float, var hp: Int = 1)
data class Thermal(
    var heat: Float = 0f,
    var capacity: Float = 100f,
    var dissipationRate: Float = 14f,
    var heatPerShot: Float = 18f,
    var recoveryRatio: Float = 0.45f,
    var overheated: Boolean = false,
)
data class Tower(var x: Float, var y: Float, var radius: Float = 180f, val thermal: Thermal, var highlight: Float = 0f)

class WasmutableRules {
    private val base = Thermal()
    val profile: Thermal = Thermal()

    fun reset() {
        profile.capacity = base.capacity
        profile.dissipationRate = base.dissipationRate
        profile.heatPerShot = base.heatPerShot
        profile.recoveryRatio = base.recoveryRatio
    }

    fun mutate(factor: Float) {
        profile.heatPerShot *= factor
        profile.dissipationRate = max(0.1f, profile.dissipationRate / factor)
    }
}

class GameView(context: Context) : View(context) {
    private val towers = mutableListOf<Tower>()
    private val enemies = mutableListOf<Enemy>()
    private val rules = WasmutableRules()
    private val touchDown = mutableMapOf<Int, Long>()

    private var spawnTimer = 0f
    private var mutationTimer = 20f
    private var twoFingerWindow = -1f
    private var activeTouchCount = 0
    private var lost = false
    private var lastTick = SystemClock.uptimeMillis()

    private val bgPaint = Paint().apply { color = Color.parseColor("#111827") }
    private val enemyPaint = Paint().apply { color = Color.parseColor("#F8FAFC") }
    private val towerPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 3f
        color = Color.argb(60, 160, 160, 180)
    }

    init {
        rules.reset()
        post(frame)
    }

    private val frame = object : Runnable {
        override fun run() {
            val now = SystemClock.uptimeMillis()
            val dt = ((now - lastTick).coerceAtMost(50L)) / 1000f
            lastTick = now
            update(dt)
            invalidate()
            postDelayed(this, 16L)
        }
    }

    private fun update(dt: Float) {
        if (twoFingerWindow >= 0f) twoFingerWindow -= dt
        if (lost) return

        spawnTimer -= dt
        if (spawnTimer <= 0f) {
            val h = max(1f, height.toFloat())
            enemies += Enemy(-20f, h * 0.5f + Random.nextFloat() * 240f - 120f)
            spawnTimer = 1.4f
        }

        mutationTimer -= dt
        if (mutationTimer <= 0f) {
            rules.mutate(1.08f)
            towers.forEach {
                it.thermal.heatPerShot = rules.profile.heatPerShot
                it.thermal.dissipationRate = rules.profile.dissipationRate
            }
            mutationTimer = 20f
        }

        val hMid = height * 0.5f
        enemies.forEach { e ->
            e.x += 120f * dt
            var bias = (hMid - e.y) * 0.25f * dt
            towers.forEach { t ->
                val d = dist(e.x, e.y, t.x, t.y)
                if (d < t.radius) {
                    val away = (e.y - t.y) / max(1f, d)
                    bias += away.coerceIn(-1f, 1f) * 95f * dt
                }
            }
            e.y += bias
        }

        if (enemies.any { it.x >= width + 20f }) {
            lost = true
            enemies.clear()
            return
        }

        towers.forEach { t ->
            val tr = t.thermal
            tr.heat = max(0f, tr.heat - tr.dissipationRate * dt)
            if (tr.overheated && tr.heat <= tr.capacity * tr.recoveryRatio) tr.overheated = false
            if (!tr.overheated) {
                val idx = enemies.indexOfFirst { dist(it.x, it.y, t.x, t.y) <= t.radius }
                if (idx >= 0) {
                    tr.heat += tr.heatPerShot
                    enemies[idx].hp -= 1
                    if (enemies[idx].hp <= 0) enemies.removeAt(idx)
                    if (tr.heat >= tr.capacity) tr.overheated = true
                }
            }
            t.highlight = max(0f, t.highlight - dt * 2.2f)
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val action = event.actionMasked
        val idx = event.actionIndex
        val pointerId = event.getPointerId(idx)
        when (action) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                activeTouchCount++
                touchDown[pointerId] = SystemClock.uptimeMillis()
                if (activeTouchCount >= 2) twoFingerWindow = 0.18f
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_CANCEL -> {
                activeTouchCount = max(0, activeTouchCount - 1)
                val heldMs = SystemClock.uptimeMillis() - (touchDown[pointerId] ?: SystemClock.uptimeMillis())
                touchDown.remove(pointerId)

                if (twoFingerWindow >= 0f) {
                    restart()
                    return true
                }
                if (heldMs >= 400L) {
                    highlightTower(event.getX(idx), event.getY(idx))
                } else {
                    if (lost) restart() else placeTower(event.getX(idx), event.getY(idx))
                }
            }
        }
        return true
    }

    private fun placeTower(x: Float, y: Float) {
        if (towers.size >= 5) return
        if (towers.any { dist(it.x, it.y, x, y) < 80f }) return
        val t = Thermal(
            capacity = rules.profile.capacity,
            dissipationRate = rules.profile.dissipationRate,
            heatPerShot = rules.profile.heatPerShot,
            recoveryRatio = rules.profile.recoveryRatio,
        )
        towers += Tower(x, y, thermal = t)
    }

    private fun highlightTower(x: Float, y: Float) {
        towers.firstOrNull { dist(it.x, it.y, x, y) <= 42f }?.highlight = 1f
    }

    private fun restart() {
        towers.clear()
        enemies.clear()
        lost = false
        spawnTimer = 0.2f
        mutationTimer = 20f
        twoFingerWindow = -1f
        rules.reset()
    }

    override fun onDraw(canvas: Canvas) {
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)
        enemies.forEach { e ->
            val p = android.graphics.Path().apply {
                moveTo(e.x, e.y - 14f)
                lineTo(e.x + 13f, e.y + 11f)
                lineTo(e.x - 13f, e.y + 11f)
                close()
            }
            canvas.drawPath(p, enemyPaint)
        }

        towers.forEach { t ->
            val ratio = (t.thermal.heat / t.thermal.capacity).coerceIn(0f, 1f)
            towerPaint.color = if (t.thermal.overheated) Color.rgb(255, 51, 25) else Color.rgb(
                (51 + ratio * 204).toInt(),
                (115 + (1f - ratio) * 102).toInt(),
                (255 - ratio * 255).toInt(),
            )
            canvas.drawCircle(t.x, t.y, 28f, towerPaint)
            canvas.drawCircle(t.x, t.y, t.radius, ringPaint)
            if (t.highlight > 0f) {
                towerPaint.color = Color.argb((t.highlight * 50).toInt(), 255, 255, 255)
                canvas.drawCircle(t.x, t.y, 38f, towerPaint)
            }
        }

        if (lost) {
            val overlay = Paint().apply { color = Color.argb(140, 0, 0, 0) }
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), overlay)
        }
    }

    private fun dist(x1: Float, y1: Float, x2: Float, y2: Float): Float =
        hypot(x1 - x2, y1 - y2)
}
