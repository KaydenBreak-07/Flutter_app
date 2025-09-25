package com.example.talent_find;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.tensorflow.lite.Interpreter;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

public class MLNativePlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;
  private Context context;
  private Interpreter tflite;
  private static final String TAG = "MLNativePlugin";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ml_native");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
    loadModel();
  }

  private void loadModel() {
    try {
      AssetManager assetManager = context.getAssets();
      ByteBuffer modelBuffer = loadModelFile(assetManager, "flutter_assets/assets/models/jump_height_model.tflite");
      tflite = new Interpreter(modelBuffer);
      Log.d(TAG, "Jump height model loaded successfully");
      Log.d(TAG, "Input shape: " + java.util.Arrays.toString(tflite.getInputTensor(0).shape()));
      Log.d(TAG, "Output shape: " + java.util.Arrays.toString(tflite.getOutputTensor(0).shape()));
    } catch (IOException e) {
      Log.e(TAG, "Failed to load model", e);
    }
  }

  private ByteBuffer loadModelFile(AssetManager assetManager, String modelPath) throws IOException {
    java.io.InputStream inputStream = assetManager.open(modelPath);
    byte[] modelBytes = new byte[inputStream.available()];
    inputStream.read(modelBytes);
    inputStream.close();

    ByteBuffer buffer = ByteBuffer.allocateDirect(modelBytes.length)
            .order(ByteOrder.nativeOrder());
    buffer.put(modelBytes);
    buffer.rewind();
    return buffer;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "analyzeFrame":
        analyzeFrame(call, result);
        break;
      case "analyzeVideo":
        analyzeVideo(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void analyzeFrame(MethodCall call, Result result) {
    try {
      if (tflite == null) {
        result.error("MODEL_NOT_LOADED", "TensorFlow Lite model not loaded", null);
        return;
      }

      // Get frame data from Flutter
      List<Integer> frameDataList = call.argument("frameData");
      if (frameDataList == null || frameDataList.isEmpty()) {
        result.error("INVALID_DATA", "Frame data is null or empty", null);
        return;
      }

      // Convert frame data to input format your model expects
      ByteBuffer inputBuffer = preprocessFrame(frameDataList);

      // Run inference
      float[][] output = new float[1][1]; // Adjust based on your model's output shape
      tflite.run(inputBuffer, output);

      // Extract jump height prediction
      float jumpHeight = output[0][0];

      Log.d(TAG, "Jump height prediction: " + jumpHeight);

      // Return result to Flutter
      result.success(jumpHeight);

    } catch (Exception e) {
      Log.e(TAG, "Error analyzing frame", e);
      result.error("ANALYSIS_ERROR", e.getMessage(), null);
    }
  }

  private void analyzeVideo(MethodCall call, Result result) {
    try {
      if (tflite == null) {
        result.error("MODEL_NOT_LOADED", "TensorFlow Lite model not loaded", null);
        return;
      }

      // Get list of frames from Flutter
      List<List<Integer>> framesData = call.argument("framesData");
      if (framesData == null || framesData.isEmpty()) {
        result.error("INVALID_DATA", "Frames data is null or empty", null);
        return;
      }

      List<Float> jumpHeights = new ArrayList<>();
      float maxJumpHeight = 0.0f;

      // Process each frame
      for (List<Integer> frameData : framesData) {
        ByteBuffer inputBuffer = preprocessFrame(frameData);
        float[][] output = new float[1][1];
        tflite.run(inputBuffer, output);

        float jumpHeight = output[0][0];
        jumpHeights.add(jumpHeight);

        if (jumpHeight > maxJumpHeight) {
          maxJumpHeight = jumpHeight;
        }
      }

      // Calculate additional metrics
      float averageJumpHeight = 0.0f;
      for (float height : jumpHeights) {
        averageJumpHeight += height;
      }
      averageJumpHeight /= jumpHeights.size();

      // Prepare result map
      Map<String, Object> analysisResult = new HashMap<>();
      analysisResult.put("maxJumpHeight", maxJumpHeight);
      analysisResult.put("averageJumpHeight", averageJumpHeight);
      analysisResult.put("jumpHeights", jumpHeights);
      analysisResult.put("frameCount", jumpHeights.size());

      Log.d(TAG, "Video analysis complete. Max jump height: " + maxJumpHeight);

      result.success(analysisResult);

    } catch (Exception e) {
      Log.e(TAG, "Error analyzing video", e);
      result.error("ANALYSIS_ERROR", e.getMessage(), null);
    }
  }

  private ByteBuffer preprocessFrame(List<Integer> frameDataList) {
    // Convert List<Integer> to ByteBuffer
    // This assumes your model expects normalized float values
    int inputSize = frameDataList.size();
    ByteBuffer buffer = ByteBuffer.allocateDirect(inputSize * 4); // 4 bytes per float
    buffer.order(ByteOrder.nativeOrder());

    for (Integer value : frameDataList) {
      // Normalize pixel values to 0-1 range if needed
      float normalizedValue = value / 255.0f;
      buffer.putFloat(normalizedValue);
    }

    buffer.rewind();
    return buffer;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    if (tflite != null) {
      tflite.close();
      tflite = null;
    }
  }
}