package com.yasmen.pocketly

import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import es.antonborri.home_widget.HomeWidgetLaunchIntent

object PocketlyWidgetIntents {
    const val REQUEST_OPEN_APP = 1101
    const val REQUEST_ADD_EXPENSE = 1102

    val addExpenseUri: Uri = Uri.parse("pocketly://widget/add-expense")

    fun openApp(context: Context): PendingIntent =
        activity(context, uri = null, requestCode = REQUEST_OPEN_APP)

    fun addExpense(context: Context): PendingIntent =
        activity(context, uri = addExpenseUri, requestCode = REQUEST_ADD_EXPENSE)

    private fun activity(
        context: Context,
        uri: Uri?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data = uri
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= 23) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        if (Build.VERSION.SDK_INT < 34) {
            return PendingIntent.getActivity(context, requestCode, intent, flags)
        }
        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= 35) {
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        } else {
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            flags,
            options.toBundle(),
        )
    }
}
