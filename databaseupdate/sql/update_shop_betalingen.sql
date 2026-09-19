CREATE PROCEDURE `dierenpension`.`update_shop_betalingen` ()
BEGIN

  DECLARE cursor_end INT;

  DECLARE v_factuur_id BIGINT(20);
  DECLARE v_betaal_datum DATETIME;
  DECLARE v_betaal_wijze VARCHAR(20);
  DECLARE v_voorschot_bedrag DECIMAL(19,2);
  DECLARE v_totaal_bedrag DECIMAL(19,2);
  DECLARE v_totaal_betaald_betalingen DECIMAL(19,2);

  DECLARE v_betaling_id BIGINT(20);

  DECLARE facturen_cursor CURSOR FOR
    SELECT
      f.shop_id,
      f.betaal_datum,
      f.betaal_wijze,
      f.voorschot_bedrag,
      sum(p.product_prijs * p.product_aantal) - f.korting_bedrag + f.administratie_kosten AS totaal_bedrag,
      (SELECT
         sum(b.bedrag)
       FROM betalingen AS b
       INNER JOIN shop_factuur_betalingen AS prb ON b.betaling_id = prb.betaling_id
       WHERE prb.shop_id = f.shop_id
      ) AS totaal_betaald_betalingen
    FROM shop_facturen AS f
    JOIN shop_regel_producten AS p ON f.shop_id = p.shop_id
    WHERE NOT f.betaal_datum IS NULL
    GROUP BY f.shop_id, f.betaal_datum, f.betaal_wijze, f.voorschot_bedrag, totaal_betaald_betalingen
    HAVING totaal_betaald_betalingen < totaal_bedrag OR totaal_betaald_betalingen IS NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_end = 1;


  SET cursor_end = 0;


  OPEN facturen_cursor;

  the_loop: LOOP
    FETCH facturen_cursor INTO v_factuur_id, v_betaal_datum, v_betaal_wijze, v_voorschot_bedrag, v_totaal_bedrag, v_totaal_betaald_betalingen;

    IF cursor_end <> 0 THEN
        LEAVE the_loop;
    END IF;
    
    IF NOT v_totaal_bedrag IS NULL AND v_totaal_bedrag > 0 THEN
      INSERT INTO betalingen(soort, betaal_wijze, betaal_datum, bedrag) VALUES('Betaling', v_betaal_wijze, v_betaal_datum, v_totaal_bedrag - v_voorschot_bedrag);

      SET v_betaling_id = last_insert_id();

      INSERT INTO shop_factuur_betalingen(shop_id, betaling_id) VALUES(v_factuur_id, v_betaling_id);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;