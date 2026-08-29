package com.yasmen.pocketly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale

class PocketlyHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_pocketly)
            val hasData = widgetData.getString("hw_has_data", "0") == "1"
            val storedDate = widgetData.getString("hw_today_date", "")
            val todayIsStored = storedDate == todayIso()

            val openApp = PocketlyWidgetIntents.openApp(context)
            views.setOnClickPendingIntent(R.id.widget_title, openApp)
            views.setOnClickPendingIntent(R.id.widget_placeholder, openApp)
            views.setOnClickPendingIntent(R.id.widget_content, openApp)
            views.setOnClickPendingIntent(
                R.id.widget_add_expense,
                PocketlyWidgetIntents.addExpense(context),
            )

            views.setTextViewText(
                R.id.widget_title,
                widgetData.getString("hw_title", context.getString(R.string.home_widget_name))
                    ?: context.getString(R.string.home_widget_name),
            )

            if (!hasData) {
                views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                views.setViewVisibility(R.id.widget_content, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_balance_label,
                    widgetData.getString("hw_balance_label", "") ?: "",
                )
                views.setTextViewText(
                    R.id.widget_balance_value,
                    widgetData.getString("hw_balance_value", "—") ?: "—",
                )
                views.setTextViewText(
                    R.id.widget_today_label,
                    widgetData.getString("hw_today_label", "") ?: "",
                )
                val todayValue =
                    if (todayIsStored) {
                        widgetData.getString("hw_today_value", "—") ?: "—"
                    } else {
                        widgetData.getString("hw_today_zero", "—") ?: "—"
                    }
                views.setTextViewText(R.id.widget_today_value, todayValue)
            }

            views.setTextViewText(
                R.id.widget_add_expense,
                widgetData.getString(
                    "hw_add_expense",
                    context.getString(R.string.home_widget_add_expense),
                ) ?: context.getString(R.string.home_widget_add_expense),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun todayIso(): String {
        val calendar = Calendar.getInstance()
        return String.format(
            Locale.US,
            "%04d-%02d-%02d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }
}
