/* Creating constraints so users and products are all unique */
CREATE CONSTRAINT FOR (u:User)
REQUIRE (u.user_id) IS UNIQUE;

CREATE CONSTRAINT FOR (p:Product)
REQUIRE (p.product_id) IS UNIQUE;

/* Loading in data for user nodes, product nodes, and rating relationships */
LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(users).csv' AS row
MERGE (u:User { user_id: row.user_id });

LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(products).csv' AS row
MERGE (p:Product { product_id: row.product_id })
SET p.product_name = row.product_name,
    p.category     = row.category,
    p.brand        = row.brand,
    p.release_date = row.release_date;
    
LOAD CSV WITH HEADERS FROM 'file:///transactions_brand(ratings).csv' AS row
MATCH (u:User { user_id: row.user_id })
MATCH (p:Product { product_id: row.product_id })
MERGE (u)-[r:RATED]->(p)
SET r.rating = toFloat(row.rating);

/* Build an user–user relationship graph */
CALL gds.graph.project.cypher(
  'users_only',
  'MATCH (u:User) RETURN id(u) AS id',
  '
    MATCH (u1:User)-[r1:RATED]->(p:Product)<-[r2:RATED]-(u2:User)
    WHERE id(u1) < id(u2)
    WITH id(u1) AS source, id(u2) AS target,
         // Combine ratings to get a weight
         avg(r1.rating + r2.rating) / 2.0 AS weight
    RETURN source, target, weight
  '
);

/* Get similarity scores between pairs of user nodes */
CALL gds.nodeSimilarity.stream('users_only', { 
  relationshipWeightProperty: 'weight'
})
YIELD node1, node2, similarity
RETURN
  gds.util.asNode(node1).user_id AS user1,
  gds.util.asNode(node2).user_id AS user2,
  similarity
ORDER BY similarity DESC;
/* Now we can use this information to find similar users given a target user */

/* Create a product-product relationship graph */
CALL gds.graph.project.cypher(
  'productSimilarity',
  'MATCH (p:Product) 
   RETURN id(p) AS id',
   
  '
    MATCH (p1:Product), (p2:Product)
    WHERE id(p1) < id(p2)   // avoid double-counting p1<->p2 & p2<->p1
    WITH p1, p2,
         // Calculate a simple weight: +1 if brand matches, +1 if category matches
         (CASE WHEN p1.brand = p2.brand THEN 1 ELSE 0 END +
          CASE WHEN p1.category = p2.category THEN 1 ELSE 0 END
         ) AS weight
    WHERE weight > 0
    RETURN id(p1) AS source, id(p2) AS target, weight
  '
);

/* Get similarity scores between pairs of product nodes */
CALL gds.nodeSimilarity.stream(
  'productSimilarity',
  {
    relationshipWeightProperty: 'weight'
  }
)
YIELD node1, node2, similarity
RETURN
  gds.util.asNode(node1).product_id AS product1,
  gds.util.asNode(node2).product_id AS product2,
  similarity
ORDER BY similarity DESC;

/* Given a target product, find similar products */
WITH 'B09G5TSGXV' AS targetProd  // just an example

CALL gds.nodeSimilarity.stream(
  'productSimilarity',
  { relationshipWeightProperty: 'weight' }
)
YIELD node1, node2, similarity
WHERE (
  gds.util.asNode(node1).product_id = targetProd 
  OR gds.util.asNode(node2).product_id = targetProd
)
RETURN DISTINCT
  CASE WHEN gds.util.asNode(node1).product_id = targetProd
       THEN gds.util.asNode(node2).product_id
       ELSE gds.util.asNode(node1).product_id
  END AS similarProduct,
  similarity
ORDER BY similarity DESC
LIMIT 5;