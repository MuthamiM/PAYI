package com.example.payi_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WalletWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val balance = widgetData.getString("wallet_balance", "0.00")
                val currency = widgetData.getString("wallet_currency", "USD")
                
                setTextViewText(R.id.wallet_balance, balance)
                setTextViewText(R.id.wallet_currency, currency)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
