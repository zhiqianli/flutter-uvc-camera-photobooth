package com.jiangdg.ausbc.utils;

import android.content.Context;
import android.content.res.Resources;

/**
 * ResourceManager to dynamically resolve resource IDs
 * This bridges the gap between com.jiangdg.ausbc.R (referenced in libausbc code)
 * and com.chenyeju.R (actual plugin resources)
 */
public class ResourceManager {
    private static final String TAG = "ResourceManager";

    /**
     * Get a raw resource ID by name
     * @param context Android context
     * @param name Resource name (e.g., "camera_vertex")
     * @return Resource ID, or 0 if not found
     */
    public static int getRawResourceId(Context context, String name) {
        if (context == null || name == null) {
            return 0;
        }
        try {
            Resources resources = context.getResources();
            String packageName = context.getPackageName();
            return resources.getIdentifier(name, "raw", packageName);
        } catch (Exception e) {
            Logger.e(TAG, "Failed to get raw resource id for: " + name, e);
            return 0;
        }
    }

    /**
     * Get a layout resource ID by name
     */
    public static int getLayoutId(Context context, String name) {
        if (context == null || name == null) {
            return 0;
        }
        try {
            Resources resources = context.getResources();
            String packageName = context.getPackageName();
            return resources.getIdentifier(name, "layout", packageName);
        } catch (Exception e) {
            Logger.e(TAG, "Failed to get layout id for: " + name, e);
            return 0;
        }
    }

    /**
     * Get an ID resource ID by name
     */
    public static int getId(Context context, String name) {
        if (context == null || name == null) {
            return 0;
        }
        try {
            Resources resources = context.getResources();
            String packageName = context.getPackageName();
            return resources.getIdentifier(name, "id", packageName);
        } catch (Exception e) {
            Logger.e(TAG, "Failed to get id for: " + name, e);
            return 0;
        }
    }
}
