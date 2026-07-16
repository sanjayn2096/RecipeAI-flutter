# Premium purchase funnel analytics

Firebase Analytics events for conversion intent by feature and drop-off before purchase.
Project: `recipeai-89d8b`.

## Funnel events

| Step | Event | Key params |
|------|-------|------------|
| 1. CTA | `premium_cta_tap` | `source` |
| 2. Paywall open | `premium_paywall_view` | `source` |
| 3a. Subscribe | `premium_subscribe_tap` | `source`, `product_id` |
| 3b. Guest → login | `premium_subscribe_login_redirect` | `source` |
| 4. Outcome | `premium_purchase_result` | `result`, `source`, `product_id`, `error_code?` |
| Soft leave | `premium_paywall_dismiss` | `source`, `seconds_on_screen` |
| Scroll depth | `premium_paywall_scroll` | `max_section` |

`result` values: `success` | `cancel` | `error`.

### Common `source` values

| `source` | Meaning |
|----------|---------|
| `recipe_assistant` | Ask Sous Chef gate |
| `pantry_scan` | Pantry scan entry (legacy / intentional upgrade) |
| `pantry_quota` | Free weekly pantry scan quota exhausted |
| `meal_plan_days` / `meal_plan_day_picker` / `meal_plan_generate` | Meal plan limits |
| `import_quota` | Import daily quota |
| `guest_quota` / `free_quota` | Recipe gen quota |
| `guest_quota_dialog` / `free_quota_dialog` | Quota dialog CTA (before paywall) |
| `drawer` / `profile` / `profile_promo` / `ad_banner` | Explicit upgrade entry |
| `onboarding` | Onboarding soft paywall |
| `restore` | Restore-purchases path (purchase result only) |
| `unknown` | Outcome with no pending source |

## Firebase Console (no BigQuery)

1. **Analytics → Events** — open each funnel event; break down by `source` (and `result` for outcomes).
2. **Analytics → Explorations → Funnel exploration** — ordered steps:
   - `premium_cta_tap` → `premium_paywall_view` → `premium_subscribe_tap` → `premium_purchase_result` (filter `result=success`).
   - Duplicate the exploration filtered by one `source` at a time for feature-level friction.
3. **Friction signals**
   - High CTA / low view: navigation or immediate back.
   - High view / low subscribe: paywall messaging or pricing friction.
   - High subscribe / high `cancel`: store sheet abandon.
   - High `error` + `error_code`: billing or verify failures.
   - High `premium_subscribe_login_redirect`: guests wanting Premium before auth.
   - Low `seconds_on_screen` on dismiss: bounce.

## BigQuery (Analytics export)

Enable **BigQuery Export** for the Firebase project, then query `analytics_*` tables.

Event params are nested; use `UNNEST(event_params)` (or the standard param UDF pattern).

### Counts by source and stage (last 28 days)

```sql
WITH params AS (
  SELECT
    event_date,
    event_name,
    user_pseudo_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS source,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'result') AS result,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'product_id') AS product_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'error_code') AS error_code
  FROM `recipeai-89d8b.analytics_XXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name IN (
      'premium_cta_tap',
      'premium_paywall_view',
      'premium_subscribe_tap',
      'premium_subscribe_login_redirect',
      'premium_purchase_result',
      'premium_paywall_dismiss'
    )
)
SELECT
  source,
  COUNTIF(event_name = 'premium_cta_tap') AS cta,
  COUNTIF(event_name = 'premium_paywall_view') AS views,
  COUNTIF(event_name = 'premium_subscribe_tap') AS subscribe_taps,
  COUNTIF(event_name = 'premium_subscribe_login_redirect') AS guest_login_redirects,
  COUNTIF(event_name = 'premium_purchase_result' AND result = 'success') AS purchases,
  COUNTIF(event_name = 'premium_purchase_result' AND result = 'cancel') AS cancels,
  COUNTIF(event_name = 'premium_purchase_result' AND result = 'error') AS errors,
  COUNTIF(event_name = 'premium_paywall_dismiss') AS dismisses
FROM params
GROUP BY source
ORDER BY cta DESC;
```

Replace `analytics_XXXXX` with the exported dataset id from the Firebase console.

### Conversion rates by source

```sql
-- Use the same `params` CTE as above, then:
SELECT
  source,
  SAFE_DIVIDE(views, cta) AS view_rate,
  SAFE_DIVIDE(subscribe_taps, views) AS subscribe_rate,
  SAFE_DIVIDE(purchases, subscribe_taps) AS purchase_rate,
  SAFE_DIVIDE(cancels, subscribe_taps) AS cancel_rate,
  SAFE_DIVIDE(purchases, cta) AS cta_to_purchase
FROM (
  SELECT
    source,
    COUNTIF(event_name = 'premium_cta_tap') AS cta,
    COUNTIF(event_name = 'premium_paywall_view') AS views,
    COUNTIF(event_name = 'premium_subscribe_tap') AS subscribe_taps,
    COUNTIF(event_name = 'premium_purchase_result' AND result = 'success') AS purchases,
    COUNTIF(event_name = 'premium_purchase_result' AND result = 'cancel') AS cancels
  FROM params
  GROUP BY source
)
ORDER BY cta DESC;
```

### Purchase errors by source and code

```sql
SELECT
  source,
  error_code,
  COUNT(*) AS errors
FROM params
WHERE event_name = 'premium_purchase_result' AND result = 'error'
GROUP BY source, error_code
ORDER BY errors DESC;
```

## Notes

- Quota dialogs may fire a dialog `source` CTA and then a second CTA when opening the paywall (`guest_quota` / `free_quota`). Prefer paywall `source` for funnel joins.
- `premium_purchase_result.source` is set when Subscribe (or Restore) starts and is cleared after the outcome is logged.
