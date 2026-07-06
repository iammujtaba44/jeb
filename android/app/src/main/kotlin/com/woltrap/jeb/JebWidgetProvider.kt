package com.woltrap.jeb

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: this month's spend, plus the budget bar when an overall
 * budget is set. All values arrive pre-formatted from the Flutter side
 * (HomeWidgetService) via the home_widget SharedPreferences bridge.
 */
class JebWidgetProvider : HomeWidgetProvider() {

    private companion object {
        const val SUBTITLE_NORMAL = "#CCFFFFFF"

        /// Warm red that stays readable on the green card.
        const val SUBTITLE_OVER = "#FFFFC7BF"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.jeb_widget).apply {
                val month = widgetData.getString("month_label", "") ?: ""
                val spent = widgetData.getString("spent_text", null)
                val budget = widgetData.getString("budget_text", "") ?: ""
                val progress = widgetData.getInt("progress", 0)
                val over = widgetData.getBoolean("over_budget", false)
                val daily = widgetData.getString("daily_text", "") ?: ""

                setTextViewText(R.id.widget_month, month)
                setTextViewText(R.id.widget_spent, spent ?: "Open Jeb")
                setTextColor(
                    R.id.widget_subtitle,
                    Color.parseColor(if (over) SUBTITLE_OVER else SUBTITLE_NORMAL),
                )
                setViewVisibility(R.id.widget_progress, View.GONE)
                setViewVisibility(R.id.widget_progress_over, View.GONE)
                setViewVisibility(R.id.widget_daily, View.GONE)
                if (spent == null) {
                    // Nothing pushed yet (widget added before first app open).
                    setTextViewText(R.id.widget_subtitle, "to see this month's spending")
                } else if (budget.isEmpty()) {
                    setTextViewText(R.id.widget_subtitle, "spent this month")
                } else {
                    setTextViewText(
                        R.id.widget_subtitle,
                        if (over) "over the $budget budget" else "of $budget budget",
                    )
                    val bar = if (over) R.id.widget_progress_over else R.id.widget_progress
                    setViewVisibility(bar, View.VISIBLE)
                    setProgressBar(bar, 100, progress, false)
                    if (daily.isNotEmpty()) {
                        setViewVisibility(R.id.widget_daily, View.VISIBLE)
                        setTextViewText(R.id.widget_daily, daily)
                    }
                }

                // Tap anywhere on the widget to open the app.
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
