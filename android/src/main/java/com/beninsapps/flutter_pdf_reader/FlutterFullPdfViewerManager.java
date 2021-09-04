package com.beninsapps.flutter_pdf_reader;

import android.app.Activity;
import android.os.SystemClock;
import android.view.ViewGroup;
import android.widget.FrameLayout;


import com.beninsapps.flutter_pdf_reader.pdf.PDFView;
import com.beninsapps.flutter_pdf_reader.pdf.listener.OnLoadCompleteListener;

import java.io.File;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * FlutterFullPdfViewerManager
 */
class FlutterFullPdfViewerManager {

    PDFView pdfView;
    Activity activity;
    boolean closed = false;
    private boolean nightMode;

    FlutterFullPdfViewerManager(final Activity activity, final boolean nightMode) {
        this.activity = activity;
        this.nightMode = nightMode;
        this.pdfView = new PDFView(activity, null);
    }

    void openPDF(String path, final MethodChannel.Result result, final Map<String,Object> position) {
        final double zoom = (double) position.get("Zoom");
        final double xOffset = (double) position.get("XOffset");
        final double yOffset = (double) position.get("YOffset");
        final OnLoadCompleteListener loadCompleteListener = new OnLoadCompleteListener() {
            @Override
            public void loadComplete(int nbPages) {
                new Thread(new Runnable() {
                    public void run() {
                        SystemClock.sleep(300);
                        activity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    pdfView.zoomTo((float) zoom);
                                    pdfView.moveTo((float) xOffset,(float) yOffset);
                                    result.success(true);
                                } catch (Exception e) {
                                    e.printStackTrace();
                                    result.success(false);
                                }
                            }
                        });
                    }
                }).start();
            }
        };
        File file = new File(path);
        pdfView.fromFile(file)
                .enableSwipe(true)
                .swipeHorizontal(false)
                .enableDoubletap(true)
                .defaultPage(0)
                .nightMode(nightMode)
                .onLoad(loadCompleteListener)
                .load();
    }

    void openPdfFromNetwork(final String path, final MethodChannel.Result result, final Map<String,Object> position) {
        final double zoom = (double) position.get("Zoom");
        final double xOffset = (double) position.get("XOffset");
        final double yOffset = (double) position.get("YOffset");
        final OnLoadCompleteListener loadCompleteListener = new OnLoadCompleteListener() {
            @Override
            public void loadComplete(int nbPages) {
                new Thread(new Runnable() {
                    public void run() {
                        SystemClock.sleep(300);
                        activity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    pdfView.zoomTo((float) zoom);
                                    pdfView.moveTo((float) xOffset,(float) yOffset);
                                    result.success(true);
                                } catch (Exception e) {
                                    e.printStackTrace();
                                    result.success(false);
                                }
                            }
                        });
                    }
                }).start();
            }
        };
        new Thread(new Runnable() {
            public void run() {
                try {
                    URL url = new URL(path);
                    HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
                    urlConnection.setRequestMethod("GET");
                    urlConnection.setDoOutput(true);
                    urlConnection.connect();
                    InputStream inputStream = urlConnection.getInputStream();
                    pdfView.fromStream(inputStream)
                            .enableSwipe(true)
                            .swipeHorizontal(false)
                            .enableDoubletap(true)
                            .defaultPage(0)
                            .nightMode(nightMode)
                            .onLoad(loadCompleteListener)
                            .load();
                } catch (Exception e) {
                    e.printStackTrace();
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            result.success(false);
                        }
                    });
                }
            }
        }).start();
    }

    void resize(FrameLayout.LayoutParams params) {
        pdfView.setLayoutParams(params);
    }

    void close(MethodCall call, MethodChannel.Result result) {
        Map<String,Object> pos = new HashMap<>();
        if (pdfView != null) {
            pos.put("Zoom",pdfView.getZoom());
            pos.put("XOffset",pdfView.getCurrentXOffset());
            pos.put("YOffset",pdfView.getCurrentYOffset());
            ViewGroup vg = (ViewGroup) (pdfView.getParent());
            vg.removeView(pdfView);
        }
        pdfView = null;
        if (result != null) {
            result.success(pos);
        }
        closed = true;
        FlutterPdfReaderPlugin.methodChannel.invokeMethod("onDestroy", null);
    }

    void close() {
        close(null, null);
    }
}