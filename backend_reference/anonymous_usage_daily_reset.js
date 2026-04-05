/**
 * Drop-in shape for /generate-recipe anonymous branch (Node + Firestore).
 * Merge into your route: use UTC dayKey so it matches the Flutter client mirror.
 *
 * const todayKey = new Date().toISOString().slice(0, 10); // YYYY-MM-DD UTC
 *
 * const usageRef = admin.firestore().collection("anonymous_usage").doc(anonymousId);
 * const doc = await usageRef.get();
 * let count = 0;
 * let storedDay = null;
 * if (doc.exists) {
 *   const data = doc.data();
 *   count = data.count || 0;
 *   storedDay = data.dayKey || null;
 * }
 * if (storedDay !== todayKey) {
 *   count = 0;
 * }
 * if (count >= 2) {
 *   return res.status(403).json({
 *     error: "Free limit reached. Please create an account.",
 *   });
 * }
 *
 * // Optional: move increment to AFTER successful Gemini + parse, so failed AI calls don't consume quota.
 * await usageRef.set(
 *   {
 *     count: count + 1,
 *     dayKey: todayKey,
 *     lastUsedAt: new Date(),
 *   },
 *   { merge: true },
 * );
 */
