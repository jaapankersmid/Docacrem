CREATE PROCEDURE `dierenpension`.`update_pension_reservering_administratie_kosten` ()
BEGIN

  DECLARE cursor_end INT;

  DECLARE v_factuur_id BIGINT(20);
  DECLARE v_administratie_kosten DECIMAL(19,2);
  DECLARE v_first_factuur_regel_id BIGINT(20);
  DECLARE v_admin_product VARCHAR(100);

  DECLARE v_betaling_id BIGINT(20);

  DECLARE facturen_cursor CURSOR FOR
    SELECT
      f.factuur_id,
      f.administratie_kosten,
      (SELECT max(fr2.factuur_regel_id) FROM factuur_regels AS fr2 WHERE fr2.factuur_id=f.factuur_id) AS first_factuur_regel,
      (SELECT count(p1.product_naam) FROM factuur_regels AS fr1 INNER JOIN factuur_regel_producten AS p1 ON fr1.factuur_regel_id = p1.factuur_regel_id AND p1.product_naam = 'Administratiekosten' WHERE fr1.factuur_id=f.factuur_id) AS admin_product
    FROM facturen AS f
    JOIN factuur_regels AS r ON f.factuur_id = r.factuur_id
    JOIN factuur_regel_producten AS p ON r.factuur_regel_id = p.factuur_regel_id
    WHERE NOT f.administratie_kosten IS NULL AND f.administratie_kosten > 0
    GROUP BY f.factuur_id, f.administratie_kosten
    HAVING (admin_product IS NULL OR admin_product = 0);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_end = 1;


  SET cursor_end = 0;


  OPEN facturen_cursor;

  the_loop: LOOP
    FETCH facturen_cursor INTO v_factuur_id, v_administratie_kosten, v_first_factuur_regel_id, v_admin_product;

    IF cursor_end <> 0 THEN
        LEAVE the_loop;
    END IF;
    
    IF v_admin_product IS NULL OR v_admin_product = 0 THEN
      INSERT INTO factuur_regel_producten(factuur_regel_id, product_naam, product_btw, product_prijs, product_aantal, korting_bedrag) VALUES(v_first_factuur_regel_id, 'Administratiekosten', 19, v_administratie_kosten, 1, 0);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;