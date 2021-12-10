package com.ayoub.viewer_model

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.SurfaceTexture
import android.graphics.drawable.BitmapDrawable
import android.util.Log
import android.view.MotionEvent
import android.view.View
import androidx.annotation.NonNull
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.rajawali3d.Object3D
import org.rajawali3d.lights.DirectionalLight
import org.rajawali3d.lights.SpotLight
import org.rajawali3d.loader.ALoader
import org.rajawali3d.loader.LoaderOBJ
import org.rajawali3d.loader.async.IAsyncLoaderCallback
import org.rajawali3d.materials.Material
import org.rajawali3d.materials.methods.DiffuseMethod
import org.rajawali3d.materials.textures.ATexture
import org.rajawali3d.materials.textures.Texture
import org.rajawali3d.math.vector.Vector3
import org.rajawali3d.primitives.Sphere
import org.rajawali3d.renderer.Renderer
import org.rajawali3d.view.ISurface
import org.rajawali3d.view.SurfaceView
import java.io.File
import kotlin.math.tan

internal class NativeView(
    context: Context?,
    id: Int,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    private val creationParams: Map<String?, Any?>?
) :
    Renderer(context),
    PlatformView,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    // private val id: Int = id
    // private val flutterPluginBinding = flutterPluginBinding
    private val eventChannel =
        EventChannel(flutterPluginBinding.binaryMessenger, "event_viewer_model$id")
    private val channel =
        MethodChannel(flutterPluginBinding.binaryMessenger, "method_viewer_model$id")
    private val surfaceView = SurfaceView(context)
    private val gson = Gson()
    private var events: EventChannel.EventSink? = null
    private lateinit var mObject: Object3D

    override fun getView(): View {
        return surfaceView
    }

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        frameRate = 60.0
        setTransparent()
        surfaceView.setFrameRate(frameRate)
        surfaceView.renderMode = ISurface.RENDERMODE_WHEN_DIRTY
        surfaceView.setSurfaceRenderer(this)
        surfaceView.renderMode = ISurface.RENDERMODE_WHEN_DIRTY
        // this.setAntiAliasingMode(ISurface.ANTI_ALIASING_CONFIG.COVERAGE)
    }

    private fun addLightSpotLight(position: Vector3) {
        val spotLight = SpotLight(position.x.toFloat(), position.y.toFloat(), position.z.toFloat())
        spotLight.enableLookAt()
        spotLight.lookAt = Vector3.ZERO
        spotLight.setColor(1.0f, 1.0f, 1.0f)
        spotLight.power = 3f
        currentScene.addLight(spotLight)
    }

    private fun addLightDirectionalLight(position: Vector3) {
        val directionalLight = DirectionalLight(position.x, position.y, position.z)
        directionalLight.setColor(1.0f, 1.0f, 1.0f)
        directionalLight.power = 3f
        directionalLight.enableLookAt()
        directionalLight.lookAt = Vector3.ZERO
        currentScene.addLight(directionalLight)
    }

    override fun initScene() {
        addLightSpotLight(Vector3(1.0, 1.0, 1.0))
        addLightSpotLight(Vector3(-1.0, 1.0, 1.0))
        addLightDirectionalLight(Vector3(1.0, 1.0, 1.0))
        addLightDirectionalLight(Vector3(-1.0, 1.0, 1.0))
        // currentScene.backgroundColor = Color.WHITE
        // view.setBackgroundColor(Color.WHITE)
        currentCamera.farPlane = 5000.0
        currentCamera.nearPlane = 0.1
        currentCamera.z = 4.2
        loadFirstModel()
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onOffsetsChanged(
        xOffset: Float,
        yOffset: Float,
        xOffsetStep: Float,
        yOffsetStep: Float,
        xPixelOffset: Int,
        yPixelOffset: Int
    ) {
        events?.success(
            mapOf(
                "event" to "OffsetsChanged",
                "data" to mapOf(
                    "xOffset" to xOffset,
                    "yOffset" to yOffset,
                    "xOffsetStep" to xOffsetStep,
                    "yOffsetStep" to yOffsetStep,
                    "xPixelOffset" to xPixelOffset,
                    "yPixelOffset" to yPixelOffset
                )
            )
        )

    }

    override fun onTouchEvent(event: MotionEvent?) {
        if (event != null) {
            // event.classification;
            events?.success(
                mapOf(
                    "event" to "touch",
                    "data" to gson.toJson(event)
                )
            )
        }
    }

    /*
    override fun onRender(elapsedRealtime: Long, deltaTime: Double) {
        super.onRender(elapsedRealtime, deltaTime)
    }
     */

    private fun loadFirstModel() {
        val initialModel = creationParams!!["initialModel"] as Map<*, *>?
        if (initialModel?.isNotEmpty() == true) {
            val path = initialModel["path"]!! as String
            val texture = initialModel["texture"] as String?
            val loader = LoaderOBJ(this, File(path))
            loadModel(loader, texture)
        }
    }

    private fun setTransparent() {
        val transparentBackground = creationParams!!["transparentBackground"] as Boolean
        surfaceView.setTransparent(transparentBackground)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "transparentBackground" -> {
                val value = call.argument<Boolean>("value")!!
                surfaceView.setTransparent(value)
                result.success(value)
            }
            "backgroundImage" -> {
                val p = call.argument<String>("path")!!
                val path = if (p.contains("flutter"))
                    flutterPluginBinding.flutterAssets.getAssetFilePathByName(p)
                    else p
                val image = BitmapDrawable.createFromPath(path)
                surfaceView.background = image
                result.success(null)
            }
            "loadTexture" -> {
                // val path = call.argument<String>("path")!!
                val texture = call.argument<String>("texture")
                mObject.material = loadTexture(texture)
                result.success(null)
            }
            "loadModel" -> {
                val path = call.argument<String>("path")!!
                val texture = call.argument<String>("texture")
                val loader = LoaderOBJ(this, File(path))
                loadModel(loader, texture, result)
            }
            "loadEarth" -> {
                loadEarth()
                result.success(null)
            }
            "rotate" -> {
                val x = call.argument<Double>("x")!!
                val y = call.argument<Double>("y")!!
                val z = call.argument<Double>("z")!!
                mObject.rotX = x
                mObject.rotY = y
                mObject.rotZ = z
                result.success(null)
            }
            "moveCam" -> {
                val x = call.argument<Double>("x")!!
                val y = call.argument<Double>("y")!!
                val z = call.argument<Double>("z")!!
                currentCamera.position = Vector3(x, y, z)
                result.success(null)
            }
            /*
            "getRotation" -> {
                result.success(mObject.rotY)
            }
            */
            else -> result.notImplemented()
        }
    }

    private fun loadModel(
        loader: ALoader,
        texture: String? = null,
        result: MethodChannel.Result? = null
    ): ALoader {
        return super.loadModel(loader, object : IAsyncLoaderCallback {
            override fun onModelLoadComplete(l: ALoader) {
                currentScene.clearChildren()
                val loader = l as LoaderOBJ
                mObject = loader.parsedObject
                mObject.material = loadTexture(texture)
                val box = mObject.boundingBox.max
                currentCamera.position = Vector3(
                    2 * box.x,
                    2 * box.y,
                    6 * listOf(box.y, box.x).max()!! / tan(currentCamera.fieldOfView)
                )
                currentCamera.enableLookAt()
                currentCamera.lookAt = Vector3.ZERO
                mObject.position = Vector3(0.0, -box.y / 2, 0.0)
                // mObject.position = Vector3.ZERO
                currentScene.addChild(mObject)
                result?.success(null)
                events?.success(
                    mapOf(
                        "event" to "loading",
                        "data" to mapOf("status" to false)
                    )
                )
                events?.success(
                    mapOf(
                        "event" to "cameraPosition",
                        "data" to gson.toJson(currentCamera.position)
                    )
                )
            }

            override fun onModelLoadFailed(loader: ALoader?) {
                result?.error("CAN_NOT_LOAD", "Model load failed", "")
                events?.error("CAN_NOT_LOAD", "Model load failed", "")

            }
        }, loader.tag)
    }

    private fun loadTexture(p: String? = null): Material {
        val material = Material()
        material.enableLighting(true)
        material.diffuseMethod = DiffuseMethod.Lambert()
        // material.color = Color.GREEN
        material.ambientColor = Color.LTGRAY
        material.colorInfluence = 0f
        if (p != null) {
            val path = if (p.contains("flutter"))
                flutterPluginBinding.flutterAssets.getAssetFilePathByName(p)
                else p
            val image = if (path.contains("flutter"))
                BitmapFactory.decodeStream(context.assets.open(path))
                else BitmapFactory.decodeFile(path)
            val texture = Texture("path", image)
            try {
                material.addTexture(texture)
            } catch (error: ATexture.TextureException) {
                Log.d("BasicRenderer.initScene", error.toString())
            }
        }
        return material
    }

    private fun loadEarth() {
        currentScene.clearChildren()
        mObject = Sphere(1f, 24, 24)
        mObject.material = loadTexture()
        mObject.position = Vector3.ZERO
        currentScene.addChild(mObject)
        currentCamera.position = Vector3(.0, .0, 6.0)
        events?.success(
            mapOf(
                "event" to "loadEarth",
                "data" to mapOf("status" to false)
            )
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onRenderSurfaceDestroyed(surface: SurfaceTexture?) {
        super.onRenderSurfaceDestroyed(surface)
    }

    override fun onInputConnectionLocked() {
        this.onPause()
        events?.success(
            mapOf(
                "event" to "onInputConnectionLocked"
            )
        )
    }

    override fun onInputConnectionUnlocked() {
        this.onResume()
        events?.success(
            mapOf(
                "event" to "onInputConnectionUnlocked"
            )
        )
    }
}
