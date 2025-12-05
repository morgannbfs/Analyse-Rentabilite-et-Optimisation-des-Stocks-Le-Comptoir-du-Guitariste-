-- ANALYSE CLIENTS 
--- 3. ETUDE DES NOUVEAUX CLIENTS
------- 1. Analyse des Produits d’Entrée
------- 2. Taux de conversion en clients récurrents

------------------------------------------------------------
------- 1. Analyse des Produits d’Entrée
------------------------------------------------------------
-- On identifie les produits qui attirent les nouveaux clients en analysant ceux vendus lors de la première vente de chaque client.

WITH 
	-- On répertorie la date de la première transaction de chaque client :
	premiere_transaction AS (
		SELECT
			client_id,
			MIN(date_transaction) AS date_transaction_1
		FROM fact_ventes
		
		GROUP BY 
			client_id
)

-- On classe les catégories de produits les plus vendues lors du premier achat de chaque client :
SELECT 	
	categorie,
	COUNT(order_id) AS nombre_premier_achat

FROM fact_ventes fv

INNER JOIN premiere_transaction pt 
	ON fv.client_id = pt.client_id
	AND fv.date_transaction=pt.date_transaction_1

INNER JOIN dim_produits dp
	ON dp.produit_id = fv.produit_id

GROUP BY categorie
ORDER BY nombre_premier_achat DESC ;


------------------------------------------------------------
------- 2. Taux de rétention en clients récurrents
------------------------------------------------------------
-- On identifie le nombre de clients qui reviennent après leur premier achat:


WITH 
F AS (
	SELECT 
			dim_clients.client_id,			
			-- Nombre de transactions effectuées par client (Frequence):
			COUNT(fact_ventes.date_transaction) AS nombre_transactions,
			SUM(chiffre_affaire_transaction) AS total_CA_client
			
	FROM dim_clients
	
	LEFT JOIN fact_ventes
		ON fact_ventes.client_id = dim_clients.client_id
	
	GROUP BY dim_clients.client_id

			
),
	
clients AS (	
	SELECT 
		--Nombre total de clients ayant renouvelé un achat:
		SUM( CASE 
			WHEN nombre_transactions >=2 THEN 1
			ELSE 0
		END) AS client_2_achats_min,

		-- Nombre total de clients ayant acheté au moins une fois:
		SUM(CASE
			WHEN nombre_transactions >=1 THEN 1
			ELSE 0
		END) AS total_clients_1_achat_min
		
	FROM F
)

-- On identifie le taux de rétention des clients :
SELECT 
	client_2_achats_min,
	total_clients_1_achat_min,
	ROUND((client_2_achats_min::NUMERIC*100)/total_clients_1_achat_min,2) AS taux_de_conversion
FROM clients

;




















