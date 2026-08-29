package com.yasmen.pocketly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PocketlyQuickExpenseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_expense)
            views.setTextViewText(
                R.id.widget_quick_title,
                widgetData.getString(
                    "hw_quick_title",
                    context.getString(R.string.home_widget_quick_name),
                ) ?: context.getString(R.string.home_widget_quick_name),
            )
            views.setTextViewText(
                R.id.widget_add_expense,
                widgetData.getString(
                    "hw_add_expense",
                    context.getString(R.string.home_widget_add_expense),
                ) ?: context.getString(R.string.home_widget_add_expense),
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_root,
                PocketlyWidgetIntents.addExpense(context),
            )
            views.setOnClickPendingIntent(
                R.id.widget_add_expense,
                PocketlyWidgetIntents.addExpense(context),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
