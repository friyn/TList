package com.friyn.tlist

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FinanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.finance_widget)

            val balance = widgetData.getString("balance", "-") ?: "-"
            views.setTextViewText(R.id.txt_title, "Balance")
            views.setTextViewText(R.id.txt_balance, balance)

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.txt_title, pendingIntent)    
            views.setOnClickPendingIntent(R.id.txt_balance, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
