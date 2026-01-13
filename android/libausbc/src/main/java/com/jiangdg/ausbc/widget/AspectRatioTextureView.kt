/*
 * Copyright 2017-2023 Jiangdg
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.jiangdg.ausbc.widget

import android.content.Context
import android.content.res.Configuration
import android.util.AttributeSet
import android.view.Surface
import android.view.TextureView
import com.jiangdg.ausbc.utils.Logger
import kotlin.math.abs

/** Adaptive TextureView
 * Aspect ratio (width:height, such as 4:3, 16:9).
 *
 * @author Created by jiangdg on 2021/12/23
 */
class AspectRatioTextureView: TextureView, IAspectRatio {

    private var mAspectRatio = -1.0

    constructor(context: Context) : this(context, null)
    constructor(context: Context, attributeSet: AttributeSet?) : this(context, attributeSet, 0)
    constructor(context: Context, attributeSet: AttributeSet?, defStyleAttr: Int) : super(context, attributeSet, defStyleAttr)

    override fun setAspectRatio(width: Int, height: Int) {
        post {
            // 修复竖屏显示问题：如果输入是横屏（宽>高），则反转比例以适配竖屏旋转
            if (width > height) {
                setAspectRatio(height.toDouble() / width)
            } else {
                setAspectRatio(width.toDouble() / height)
            }
        }

    }

    override fun getSurfaceWidth(): Int  = measuredWidth

    override fun getSurfaceHeight(): Int  = measuredHeight

    override fun getSurface(): Surface? {
        return try {
            Surface(surfaceTexture)
        } catch (e: Exception) {
            null
        }
    }

    override fun postUITask(task: () -> Unit) {
        post {
            task()
        }
    }

    private fun setAspectRatio(aspectRatio: Double) {
        if (aspectRatio < 0 || mAspectRatio == aspectRatio) {
            return
        }
        mAspectRatio = aspectRatio
        Logger.i(TAG, "AspectRatio = $mAspectRatio")
        requestLayout()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)
        setMeasuredDimension(width, height)
    }


    companion object {
        private const val TAG = "AspectRatioTextureView"
    }
}