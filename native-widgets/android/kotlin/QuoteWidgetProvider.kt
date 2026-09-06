// Copy this file to:
//   android/app/src/main/kotlin/<your/package/path>/QuoteWidgetProvider.kt
// (the same folder that already contains MainActivity.kt)
//
// IMPORTANT: change the `package` line below to match the package declared
// at the top of your MainActivity.kt exactly.

package com.example.productivity_hub

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kotlin.random.Random

/**
 * A home-screen widget showing a motivational quote. Picks a new random
 * quote whenever Android refreshes the widget (see updatePeriodMillis in
 * quote_widget_info.xml) and whenever the refresh icon is tapped — entirely
 * in native code, so it works even if the Flutter app has never been opened.
 *
 * Keep this list in sync with lib/data/quotes.dart if you add/edit quotes.
 */
class QuoteWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.example.productivity_hub.REFRESH_QUOTE"

        val QUOTES = listOf(
            Pair("Discipline is choosing between what you want now and what you want most.", "Abraham Lincoln"),
            Pair("The expert in anything was once a beginner.", "Helen Hayes"),
            Pair("Small steps every day add up to big results.", "Unknown"),
            Pair("You don't have to be great to start, but you have to start to be great.", "Zig Ziglar"),
            Pair("Success is the sum of small efforts repeated day in and day out.", "Robert Collier"),
            Pair("Focus on progress, not perfection.", "Unknown"),
            Pair("The future depends on what you do today.", "Mahatma Gandhi"),
            Pair("Push yourself, because no one else is going to do it for you.", "Unknown"),
            Pair("A little progress each day adds up to big results.", "Unknown"),
            Pair("Don't watch the clock; do what it does. Keep going.", "Sam Levenson"),
            Pair("Well done is better than well said.", "Benjamin Franklin"),
            Pair("Study while others are sleeping; work while others are loafing.", "William A. Ward")
        )

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val (text, author) = QUOTES[Random.nextInt(QUOTES.size)]
            val views = RemoteViews(context.packageName, R.layout.quote_widget)
            views.setTextViewText(R.id.widget_quote_text, "\u201C$text\u201D")
            views.setTextViewText(R.id.widget_quote_author, "\u2014 $author")

            // Tapping the quote text opens the app.
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val openPendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPendingIntent)

            // Tapping the refresh icon picks a new random quote in place,
            // without opening the app.
            val refreshIntent = Intent(context, QuoteWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context, appWidgetId, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, QuoteWidgetProvider::class.java)
            )
            for (id in widgetIds) {
                updateWidget(context, appWidgetManager, id)
            }
        }
    }
}
