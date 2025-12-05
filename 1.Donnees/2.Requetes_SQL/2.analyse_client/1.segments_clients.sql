-- ANALYSE CLIENTS 
--- 1. SEGMENTS :
------- 1. Score RF cients actifs
------- 2. Panier moyen paliers business

------------------------------------------------------------
------- 1.Score RF cients actifs
------------------------------------------------------------

------- Score RF cients actifs
WITH 
RFM AS (
    SELECT 
        dc.client_id,
        -- La recence est NULL si pas d'achat (non-acheteur)
        MAX(fv.date_transaction) AS derniere_transaction,
        
        -- Nombre de transactions (0 pour les non-acheteurs)
        COUNT(fv.date_transaction) AS nombre_transactions
    FROM dim_clients dc
    LEFT JOIN fact_ventes fv ON fv.client_id = dc.client_id
    GROUP BY dc.client_id
),

-- Calcul des scores pour les clients ACTIFS uniquement (où nombre_transactions > 0)
scores_actifs AS (
    SELECT 
        client_id,
        derniere_transaction,
        nombre_transactions,
        
        -- Récence : NTILE sur le reste des clients (ceux qui ont une date de transaction)
        -- On ordonne par date de transaction ASC pour donner le score 1 aux plus anciennes
        NTILE(4) OVER(ORDER BY derniere_transaction ASC) AS score_recency,
        
        -- Fréquence : NTILE sur le reste des clients (ceux qui ont une transaction > 0)
        NTILE(4) OVER(ORDER BY nombre_transactions ASC) AS score_frequency
        
    FROM RFM
    WHERE nombre_transactions > 0
)

-- Classement final
SELECT 
    COUNT(client_id) AS nombre_clients,
    score_recency,
    score_frequency
FROM scores_actifs
GROUP BY score_recency, score_frequency
ORDER BY score_recency DESC, score_frequency DESC;


------------------------------------------------------------
------- 2. Panier moyen paliers business
------------------------------------------------------------
 
WITH achat_client AS(
	SELECT 
			dim_clients.client_id,
			COALESCE(SUM(chiffre_affaire_transaction),0) AS total_CA_client,
			-- Nombre de transactions effectuées par client (Frequence):
			COALESCE(SUM(COALESCE(chiffre_affaire_transaction,0)),0)/NULLIF(COUNT(fact_ventes.date_transaction),0) AS achat_moyen
			
	FROM dim_clients
	
	LEFT JOIN fact_ventes
		ON fact_ventes.client_id = dim_clients.client_id
	
	GROUP BY dim_clients.client_id
	ORDER BY dim_clients.client_id ASC
)


	SELECT 
			COUNT(client_id) AS nombre_clients,
			CASE
				WHEN achat_moyen IS NULL THEN 'Pas de commande'
				WHEN achat_moyen < 20 THEN 'Petite commande (<20€)'
				WHEN achat_moyen < 60 THEN 'Commande moyenne (40-60€)'
				WHEN achat_moyen < 200 THEN 'Commande importante (60-200€)'
				WHEN achat_moyen >= 200 AND  achat_moyen < 500 THEN 'Commande très importante (200-500€)'
				WHEN achat_moyen > 500 THEN 'Commande exceptionnelle (>500€)'
			END AS commandes
	
	FROM achat_client

	GROUP BY commandes
	ORDER BY nombre_clients DESC
;




