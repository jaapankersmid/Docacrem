CREATE PROCEDURE `dierenpension`.`update_pension_reservering_betalingen` ()
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
      f.factuur_id,
      f.betaal_datum,
      f.betaal_wijze,
      f.voorschot_bedrag,
      sum(p.product_prijs * p.product_aantal - p.korting_bedrag) - (f.korting_bedrag + f.korting_verblijf_bedrag) + f.administratie_kosten - (select sum(fr1.groeps_korting_totaal + fr1.pension_toeslag_totaal) from factuur_regels as fr1 where fr1.factuur_id=f.factuur_id) AS totaal_bedrag,
      (SELECT
         sum(b.bedrag)
       FROM betalingen AS b
       INNER JOIN pension_reservering_betalingen AS prb ON b.betaling_id = prb.betaling_id
       WHERE prb.factuur_id = f.factuur_id
      ) AS totaal_betaald_betalingen
    FROM facturen AS f
    JOIN factuur_regels AS r ON f.factuur_id = r.factuur_id
    JOIN factuur_regel_producten AS p ON r.factuur_regel_id = p.factuur_regel_id
    WHERE NOT f.betaal_datum IS NULL
    GROUP BY f.factuur_id, f.betaal_datum, f.betaal_wijze, f.voorschot_bedrag, totaal_betaald_betalingen
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

      INSERT INTO pension_reservering_betalingen(factuur_id, betaling_id) VALUES(v_factuur_id, v_betaling_id);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;