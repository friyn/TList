package com.friyn.tlist

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickAddWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)

            // Set up click intents for quick actions
            val addTaskIntent = createQuickActionIntent(context, "add_task")
            val addNoteIntent = createQuickActionIntent(context, "add_note")
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

            // Set click listeners
            views.setOnClickPendingIntent(R.id.btn_add_task, addTaskIntent)
            views.setOnClickPendingIntent(R.id.btn_add_note, addNoteIntent)
            views.setOnClickPendingIntent(R.id.btn_open_app, openAppIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun createQuickActionIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("widget_action", action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val requestCode = when (action) {
            "add_task" -> 1001
            "add_note" -> 1002
            else -> 1000
        }
        
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
