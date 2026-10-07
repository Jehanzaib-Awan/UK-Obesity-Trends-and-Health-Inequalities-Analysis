SELECT
    year,
    deprivation_decile,
    obesity_prevalence,
    overweight_obesity_prevalence
FROM obesity_data
WHERE year IS NOT NULL
  AND deprivation_decile IS NOT NULL
  AND obesity_prevalence IS NOT NULL
  AND overweight_obesity_prevalence IS NOT NULL
  AND (
      deprivation_decile = 'England'
      OR deprivation_decile IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
  )
ORDER BY
    year,
    CASE WHEN deprivation_decile = 'England' THEN 0 ELSE CAST(deprivation_decile AS INTEGER) END;
