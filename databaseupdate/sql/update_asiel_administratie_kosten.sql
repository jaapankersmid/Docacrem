CREATE PROCEDURE `dierenpension`.`update_asiel_administratie_kosten` ()
BEGIN

  DECLARE cursor_end INT;

  DECLARE v_factuur_id BIGINT(20);
  DECLARE v_administratie_kosten DECIMAL(19,2);
  DECLARE v_admin_product VARCHAR(100);

  DECLARE v_betaling_id BIGINT(20);

  DECLARE facturen_cursor CURSOR FOR
    SELECT
      f.asiel_factuur_id,
      f.administratie_kosten,
      (SELECT count(p1.product_naam) FROM asiel_factuur_regel_producten AS p1 WHERE f.asiel_factuur_id = p1.asiel_factuur_id AND p1.product_naam = 'Administratiekosten') AS admin_product
    FROM asiel_facturen AS f
    JOIN asiel_factuur_regel_producten AS p ON f.asiel_factuur_id = p.asiel_factuur_id
    WHERE NOT f.administratie_kosten IS NULL AND f.administratie_kosten > 0
    GROUP BY f.asiel_factuur_id, f.administratie_kosten
    HAVING (admin_product IS NULL OR admin_product = 0);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_end = 1;


  SET cursor_end = 0;


  OPEN facturen_cursor;

  the_loop: LOOP
    FETCH facturen_cursor INTO v_factuur_id, v_administratie_kosten, v_admin_product;

    IF cursor_end <> 0 THEN
        LEAVE the_loop;
    END IF;
    
    IF v_admin_product IS NULL OR v_admin_product = 0 THEN
      INSERT INTO asiel_factuur_regel_producten(asiel_factuur_id, product_naam, product_btw, product_prijs, product_aantal) VALUES(v_factuur_id, 'Administratiekosten', 19, v_administratie_kosten, 1);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;