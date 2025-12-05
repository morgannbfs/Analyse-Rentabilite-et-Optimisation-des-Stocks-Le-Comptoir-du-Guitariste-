-- ANALYSE DESCRIPTIVE
--- 1. VUE GLOBALE SUR 3 ANS

----- 1. Indicateurs par mois et par année

----- 2. Top categories en volume 

------------------------------------------------------------
----- 1. Indicateurs par mois et par année
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
ORDER BY annee, mois ASC;


------------------------------------------------------------
----- 2.  Top categories en volume
------------------------------------------------------------

SELECT
		categorie,
		SUM(quantite_vendue) AS volume_total,
		SUM(chiffre_affaire_transaction) AS CA_total, 
		SUM(marge_transaction) AS marge_totale,
		ROUND(SUM(marge_transaction::NUMERIC)/SUM(chiffre_affaire_transaction::NUMERIC),4)*100 AS marge_pct

FROM fact_ventes
LEFT JOIN dim_produits
	ON dim_produits.produit_id = fact_ventes.produit_id
GROUP BY categorie
ORDER BY volume_total DESC
;
