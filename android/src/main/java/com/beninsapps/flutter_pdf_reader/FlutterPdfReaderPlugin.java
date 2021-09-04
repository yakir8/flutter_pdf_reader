package com.beninsapps.flutter_pdf_reader;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.pdf.PdfRenderer;
import android.os.Build;
import android.os.ParcelFileDescriptor;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Locale;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.os.HandlerThread;
import android.os.Process;
import android.os.Handler;
import android.view.Display;
import android.widget.FrameLayout;

/**
 * FlutterPdfReaderPlugin
 */
public class FlutterPdfReaderPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    static MethodChannel methodChannel;
    private EventChannel eventChannel;
    public static EventChannel.EventSink eventSink;
    Context mContext;

    private Handler backgroundHandler;
    private final Object pluginLocker = new Object();

    private FlutterFullPdfViewerManager flutterFullPdfViewerManager;
    private Activity activity;


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mContext = flutterPluginBinding.getApplicationContext();
        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.beninsapps.flutter_pdf_reader");
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),"com.beninsapps.flutter_pdf_reader/listen");
        listen();
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {
        synchronized (pluginLocker) {
            if (backgroundHandler == null) {
                HandlerThread handlerThread = new HandlerThread("flutterPdfViewer", Process.THREAD_PRIORITY_BACKGROUND);
                handlerThread.start();
                backgroundHandler = new Handler(handlerThread.getLooper());
            }
        }
        final Handler mainThreadHandler = new Handler();
        backgroundHandler.post(
                new Runnable() {
                    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
                    @Override
                    public void run() {
                        switch (call.method) {
                            case "getNumberOfPages":
                                final String numResult = getNumberOfPages((String) call.argument("filePath"));
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(numResult);
                                    }
                                });
                                break;
                            case "getPage":
                                final String pageResult = getPage((String) call.argument("filePath"), (int) call.argument("pageNumber"));
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(pageResult);
                                    }
                                });
                                break;
                            case "launch":
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        openPDF(call, result);
                                    }
                                });
                                break;
                            case "launchFromNetwork":
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        openPdfFromNetwork(call, result);
                                    }
                                });
                                break;
                            case "resize":
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        resize(call, result);
                                    }
                                });
                                break;
                            case "close":
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        close(call, result);
                                    }
                                });
                                break;
                            case "listen":
                                break;
                            default:
                                mainThreadHandler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.notImplemented();
                                    }
                                });
                                break;
                        }
                    }
                }
        );
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private String getNumberOfPages(String filePath) {
        File pdf = new File(filePath);
        try {
            PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdf, ParcelFileDescriptor.MODE_READ_ONLY));
            final int pageCount = renderer.getPageCount();
            return String.format(Locale.US, "%d", pageCount);
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }

    private String createTempPreview(Bitmap bmp, String name, int page) {
        String filePath = name.substring(name.lastIndexOf('.'));
        File file;
        try {
            String fileName = String.format(Locale.US, "%s-%d.png", filePath, page);
            file = File.createTempFile(fileName, null, mContext.getCacheDir());
            FileOutputStream out = new FileOutputStream(file);
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out);
            out.flush();
            out.close();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
        return file.getAbsolutePath();
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private String getPage(String filePath, int pageNumber) {
        File pdf = new File(filePath);
        try {
            PdfRenderer renderer = new PdfRenderer(ParcelFileDescriptor.open(pdf, ParcelFileDescriptor.MODE_READ_ONLY));
            final int pageCount = renderer.getPageCount();
            if (pageNumber > pageCount) {
                pageNumber = pageCount;
            }

            PdfRenderer.Page page = renderer.openPage(--pageNumber);

            double width = mContext.getResources().getDisplayMetrics().densityDpi * page.getWidth();
            double height = mContext.getResources().getDisplayMetrics().densityDpi * page.getHeight();
            final double docRatio = width / height;

            width = 2048;
            height = (int) (width / docRatio);
            Bitmap bitmap = Bitmap.createBitmap((int) width, (int) height, Bitmap.Config.ARGB_8888);
            // Change background to white
            Canvas canvas = new Canvas(bitmap);
            canvas.drawColor(Color.WHITE);
            // Render to bitmap
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);
            try {
                return createTempPreview(bitmap, filePath, pageNumber);
            } finally {
                // close the page
                page.close();
                // close the renderer
                renderer.close();
            }
        } catch (Exception ex) {
            System.out.println(ex.getMessage());
            ex.printStackTrace();
        }

        return null;
    }


    //API low then LOLLIPOP
    private void openPDF(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        boolean nightMode = call.argument("nightMode");
        Map<String, Object> position = call.argument("Position");
        if (flutterFullPdfViewerManager == null || flutterFullPdfViewerManager.closed) {
            flutterFullPdfViewerManager = new FlutterFullPdfViewerManager(activity, nightMode);
        }
        FrameLayout.LayoutParams params = buildLayoutParams(call);
        activity.addContentView(flutterFullPdfViewerManager.pdfView, params);
        flutterFullPdfViewerManager.openPDF(path, result, position);
        listen();
    }

    private void openPdfFromNetwork(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        boolean nightMode = call.argument("nightMode");
        Map<String, Object> position = call.argument("Position");
        if (flutterFullPdfViewerManager == null || flutterFullPdfViewerManager.closed) {
            flutterFullPdfViewerManager = new FlutterFullPdfViewerManager(activity, nightMode);
        }
        FrameLayout.LayoutParams params = buildLayoutParams(call);
        activity.addContentView(flutterFullPdfViewerManager.pdfView, params);
        flutterFullPdfViewerManager.openPdfFromNetwork(path, result, position);
    }

    private void resize(MethodCall call, final MethodChannel.Result result) {
        if (flutterFullPdfViewerManager != null) {
            FrameLayout.LayoutParams params = buildLayoutParams(call);
            flutterFullPdfViewerManager.resize(params);
        }
        result.success(null);
    }

    private void close(MethodCall call, MethodChannel.Result result) {
        if (flutterFullPdfViewerManager != null) {
            flutterFullPdfViewerManager.close(call, result);
            flutterFullPdfViewerManager = null;
        }
    }

    private  void listen(){
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
    }

    private FrameLayout.LayoutParams buildLayoutParams(MethodCall call) {
        Map<String, Number> rc = call.argument("rect");
        FrameLayout.LayoutParams params;
        if (rc != null) {
            params = new FrameLayout.LayoutParams(dp2px(activity, rc.get("width").intValue()), dp2px(activity, rc.get("height").intValue()));
            params.setMargins(dp2px(activity, rc.get("left").intValue()), dp2px(activity, rc.get("top").intValue()), 0, 0);
        } else {
            Display display = activity.getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            int width = size.x;
            int height = size.y;
            params = new FrameLayout.LayoutParams(width, height);
        }
        return params;
    }

    private int dp2px(Context context, float dp) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dp * scale + 0.5f);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
