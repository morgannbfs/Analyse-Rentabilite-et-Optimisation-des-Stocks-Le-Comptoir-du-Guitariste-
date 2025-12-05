-- ANALYSE PRODUITS 
--- 1. PERFORMaNCES PAR CATEGORIE 
------- 1. Synthèse par catégorie
------- 2. Synthèse par famille de produit
------- 3. Volume, CA ,marge brute globale

------------------------------------------------------------
------- 1. Synthèse par catégorie
------------------------------------------------------------

SELECT
    categorie,
    COUNT(quantite_vendue) AS total_transactions,
    SUM(quantite_vendue) AS volume_total_vendu,
	ROUND(((SUM(quantite_vendue) * 100.0)/SUM(SUM(quantite_vendue)) OVER ())::NUMERIC, 2) AS pct_volume_total,

    SUM(chiffre_affaire_transaction::NUMERIC) AS CA_total,
	-- % CA Global 
	ROUND(((SUM(chiffre_affaire_transaction) * 100.0)/SUM(SUM(chiffre_affaire_transaction)) OVER ())::NUMERIC, 2) AS pct_ca_global,
    SUM(marge_transaction) AS marge_brute, 
	--% Marge Globale 
	ROUND(((SUM(marge_transaction) * 100.0)/SUM(SUM(marge_transaction)) OVER ())::NUMERIC, 2) AS pct_marge_globale

		  
FROM fact_ventes
LEFT JOIN dim_produits
    ON dim_produits.produit_id = fact_ventes.produit_id
GROUP BY categorie
ORDER BY CA_total DESC
;

------------------------------------------------------------
------- 2. Synthèse par famille de produit
------------------------------------------------------------

SELECT
    CASE 
        WHEN dp.categorie IN ('Guitare Electrique', 'Guitare Folk') THEN '1 - Guitares'
        WHEN dp.categorie = 'Ampli' THEN '2 - Amplis'
        WHEN dp.categorie IN ('Cordes Electrique', 'Cordes Folk', 'Mediator', 'Sangle') THEN '3 - Consommables'
        ELSE '4 - Autres'
    END AS famille_produit,
    COUNT(quantite_vendue) AS total_transactions,
	SUM(fv.quantite_vendue) AS volume_total,
	ROUND(((SUM(quantite_vendue) * 100.0)/SUM(SUM(quantite_vendue)) OVER ())::NUMERIC, 2) AS pct_volume_total,
    SUM(fv.chiffre_affaire_transaction::NUMERIC) AS ca_total,
	ROUND(((SUM(chiffre_affaire_transaction) * 100.0)/SUM(SUM(chiffre_affaire_transaction)) OVER ())::NUMERIC, 2) AS pct_ca_global,
	SUM(marge_transaction)::NUMERIC AS marge_brute, 
	ROUND(((SUM(marge_transaction) * 100.0)/SUM(SUM(marge_transaction)) OVER ())::NUMERIC, 2) AS pct_marge_globale
    
    
FROM fact_ventes fv
INNER JOIN dim_produits dp 
    ON fv.produit_id = dp.produit_id
    
GROUP BY 
    famille_produit
	
ORDER BY 
    ca_total DESC;


------------------------------------------------------------
------- 3. Volume, CA ,marge brute globale
------------------------------------------------------------
SELECT
    categorie,
	reference_produit,
    COUNT(quantite_vendue) AS total_transactions,
	-- Volume:
    SUM(quantite_vendue) AS volume_total_vendu,
	ROUND(((SUM(quantite_vendue) * 100.0)/SUM(SUM(quantite_vendue)) OVER ())::NUMERIC, 2) AS pct_volume_total,

	--CA :
    SUM(chiffre_affaire_transaction::NUMERIC) AS CA_total,
		-- % CA Global 
	ROUND(((SUM(chiffre_affaire_transaction) * 100.0)/SUM(SUM(chiffre_affaire_transaction)) OVER ())::NUMERIC, 2) AS pct_ca_global,

	-- Marge brute : 
    SUM(marge_transaction) AS marge_brute, 
		--% Marge Globale 
	ROUND(((SUM(marge_transaction) * 100.0)/SUM(SUM(marge_transaction)) OVER ())::NUMERIC, 2) AS pct_marge_globale

		  
FROM fact_ventes
LEFT JOIN dim_produits
    ON dim_produits.produit_id = fact_ventes.produit_id
GROUP BY categorie,reference_produit
ORDER BY CA_total DESC
;

