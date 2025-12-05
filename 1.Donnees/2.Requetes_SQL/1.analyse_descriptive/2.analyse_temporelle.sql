-- ANALYSE DESCRIPTIVE
--- 2. ANALYSE TEMPORELLE:
----- 1. Variation YoY
----- 2. TOP 10 mois Chiffre d'Affaires 
----- 3. Variations sur la semaine 

------------------------------------------------------------
----- 1. Variation YoY
------------------------------------------------------------
WITH yoy_mois AS (
        SELECT
                annee,
                mois,
                SUM(quantite_vendue)::NUMERIC AS volume_total, 
                LAG(SUM(quantite_vendue)::NUMERIC, 12) OVER (ORDER BY annee, mois) AS volume_total_n_1,
                SUM(chiffre_affaire_transaction)::NUMERIC AS CA_total,
                LAG(SUM(chiffre_affaire_transaction)::NUMERIC,12) OVER (ORDER BY annee, mois) AS CA_total_n_1,
                SUM(marge_transaction)::NUMERIC AS marge_brute, 
                LAG(SUM(marge_transaction)::NUMERIC,12) OVER (ORDER BY annee, mois) AS marge_brute_n_1, 
                ROUND(SUM(chiffre_affaire_transaction)::NUMERIC/ COUNT(quantite_vendue),2) AS panier_moyen,  
                LAG(ROUND(SUM(chiffre_affaire_transaction)::NUMERIC/ COUNT(quantite_vendue),2),12) OVER (ORDER BY annee, mois) AS panier_moyen_n_1 
                
        FROM fact_ventes
        LEFT JOIN dim_dates
            ON dim_dates.date_clef = fact_ventes.date_transaction
        GROUP BY annee, mois
        ORDER BY annee, mois ASC
)

SELECT 
    annee,
    mois,
    --Variation Volume_total:
    CASE 
        WHEN volume_total_n_1 IS NULL THEN NULL
        WHEN volume_total_n_1 = 0.00 THEN NULL
        ELSE ROUND(((volume_total / volume_total_n_1) - 1) * 100, 2) 
        END AS volume_total_var_yoy,

    -- Variation CA_total:
    CASE 
        WHEN CA_total_n_1 IS NULL THEN NULL
        WHEN CA_total_n_1 = 0.00 THEN NULL
        ELSE ROUND(((CA_total / CA_total_n_1) - 1) * 100, 2) 
    END AS CA_total_var_yoy,

    -- Variation marge_brute:
    CASE 
        WHEN marge_brute_n_1 IS NULL THEN NULL
        WHEN marge_brute_n_1 = 0.00 THEN NULL
        ELSE ROUND(((marge_brute / marge_brute_n_1) - 1) * 100, 2) 
    END AS marge_brute_var_yoy,

    -- Variation panier_moyen:
    CASE 
        WHEN panier_moyen_n_1 IS NULL THEN NULL
        WHEN panier_moyen_n_1 = 0.00 THEN NULL
        ELSE ROUND(((panier_moyen / panier_moyen_n_1) - 1) * 100, 2) 
    END AS panier_moyen_var_yoy

    
FROM yoy_mois
;																										

------------------------------------------------------------
----- 2. TOP 10 mois Chiffre d'Affaires 
------------------------------------------------------------
SELECT
		annee,
		mois,
		COUNT(quantite_vendue) AS total_transactions,
		SUM(quantite_vendue) AS volume_total_vendu,
		SUM(chiffre_affaire_transaction::NUMERIC) AS CA_total, 
		SUM(marge_transaction::NUMERIC) AS marge_brute,
		ROUND(SUM(chiffre_affaire_transaction::NUMERIC)/ COUNT(quantite_vendue::NUMERIC),2) AS panier_moyen,
		ROUND(SUM(marge_transaction::NUMERIC)/SUM(chiffre_affaire_transaction::NUMERIC),4)*100 AS marge_pct

FROM fact_ventes
LEFT JOIN dim_dates
	ON dim_dates.date_clef = fact_ventes.date_transaction
GROUP BY annee, mois
ORDER BY 
		CA_total DESC
LIMIT (10)
;

------------------------------------------------------------
----- 3. Variations horaires  sur la semaine
------------------------------------------------------------


SELECT
		CASE 
			WHEN dim_dates.jour_semaine IN ('Saturday', 'Sunday') THEN 'Weekend'
			ELSE 'Jour de Semaine'
		END AS semaine_weekend,
		CASE 
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 0 AND EXTRACT(HOUR FROM heure_transaction) < 6 THEN '5'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 6 AND EXTRACT(HOUR FROM heure_transaction) < 11 THEN '1'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 11 AND EXTRACT(HOUR FROM heure_transaction) < 13 THEN '2'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 13 AND EXTRACT(HOUR FROM heure_transaction) < 17 THEN '3'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 17 AND EXTRACT(HOUR FROM heure_transaction) < 22 THEN '4'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 22 AND EXTRACT(HOUR FROM heure_transaction) <= 23 THEN '5' 
		    ELSE 'Autres'
		END AS ordre_plage,
		CASE 
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 0 AND EXTRACT(HOUR FROM heure_transaction) < 6 THEN 'Nuit'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 6 AND EXTRACT(HOUR FROM heure_transaction) < 11 THEN 'Matin'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 11 AND EXTRACT(HOUR FROM heure_transaction) < 13 THEN 'Midi'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 13 AND EXTRACT(HOUR FROM heure_transaction) < 17 THEN 'Après-midi'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 17 AND EXTRACT(HOUR FROM heure_transaction) < 22 THEN 'Soir'
		    WHEN EXTRACT(HOUR FROM heure_transaction) >= 22 AND EXTRACT(HOUR FROM heure_transaction) <= 23 THEN 'Nuit' 
		    ELSE 'Autres'
		END AS plage_horaire,
	
		COUNT(quantite_vendue) AS total_transactions,
		SUM(quantite_vendue) AS volume_total_vendu,
		SUM(chiffre_affaire_transaction::NUMERIC) AS CA_total, 
		SUM(marge_transaction::NUMERIC) AS marge_brute,
		ROUND(SUM(chiffre_affaire_transaction::NUMERIC)/ COUNT(quantite_vendue::NUMERIC),2) AS panier_moyen,
		ROUND(SUM(marge_transaction::NUMERIC)/SUM(chiffre_affaire_transaction::NUMERIC),4)*100 AS marge_pct

FROM fact_ventes
LEFT JOIN dim_dates
	ON dim_dates.date_clef = fact_ventes.date_transaction
GROUP BY 
		semaine_weekend,
		plage_horaire,
		ordre_plage

ORDER BY ca_total DESC
;
