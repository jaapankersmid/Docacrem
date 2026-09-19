CREATE PROCEDURE `dierenpension`.`update_asiel_voorschotten` ()
BEGIN

  DECLARE cursor_end INT;

  DECLARE v_factuur_id BIGINT(20);
  DECLARE v_voorschot_datum DATETIME;
  DECLARE v_voorschot_betaal_wijze VARCHAR(20);
  DECLARE v_voorschot_bedrag DECIMAL(19,2);
  DECLARE v_betaling_count INT;

  DECLARE v_betaling_id BIGINT(20);

  DECLARE facturen_cursor CURSOR FOR
    SELECT
      f.asiel_factuur_id,
      f.voorschot_datum,
      f.voorschot_betaal_wijze,
      f.voorschot_bedrag,
      (SELECT
         count(b.betaling_id)
       FROM betalingen AS b
       INNER JOIN asiel_factuur_betalingen AS prb ON b.betaling_id = prb.betaling_id
       WHERE prb.asiel_factuur_id = f.asiel_factuur_id
      ) AS betaling_count
    FROM asiel_facturen AS f
    WHERE NOT f.voorschot_bedrag IS NULL AND f.voorschot_bedrag > 0
    GROUP BY f.asiel_factuur_id, f.voorschot_datum, f.voorschot_betaal_wijze, f.voorschot_bedrag, betaling_count
    HAVING betaling_count = 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_end = 1;


  SET cursor_end = 0;


  OPEN facturen_cursor;

  the_loop: LOOP
    FETCH facturen_cursor INTO v_factuur_id, v_voorschot_datum, v_voorschot_betaal_wijze, v_voorschot_bedrag, v_betaling_count;

    IF cursor_end <> 0 THEN
        LEAVE the_loop;
    END IF;
    
    IF NOT v_voorschot_bedrag IS NULL AND v_voorschot_bedrag > 0 THEN
      INSERT INTO betalingen(soort, betaal_wijze, betaal_datum, bedrag) VALUES('Voorschot', v_voorschot_betaal_wijze, v_voorschot_datum, v_voorschot_bedrag);

      SET v_betaling_id = last_insert_id();

      INSERT INTO asiel_factuur_betalingen(asiel_factuur_id, betaling_id) VALUES(v_factuur_id, v_betaling_id);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;