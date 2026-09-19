CREATE PROCEDURE `dierenpension`.`update_salon_afspraak_administratie_kosten` ()
BEGIN

  DECLARE cursor_end INT;

  DECLARE v_factuur_id BIGINT(20);
  DECLARE v_administratie_kosten DECIMAL(19,2);
  DECLARE v_first_factuur_regel_id BIGINT(20);
  DECLARE v_admin_product VARCHAR(100);

  DECLARE v_betaling_id BIGINT(20);

  DECLARE facturen_cursor CURSOR FOR
    SELECT
      f.salon_afspraak_id,
      f.administratie_kosten,
      (SELECT max(fr2.salon_afspraak_regel_id) FROM salon_afspraak_regels AS fr2 WHERE fr2.salon_afspraak_id=f.salon_afspraak_id) AS first_factuur_regel,
      (SELECT count(p1.product_naam) FROM salon_afspraak_regels AS fr1 INNER JOIN salon_afspraak_regel_producten AS p1 ON fr1.salon_afspraak_regel_id = p1.salon_afspraak_regel_id AND p1.product_naam = 'Administratiekosten' WHERE fr1.salon_afspraak_id=f.salon_afspraak_id) AS admin_product
    FROM salon_afspraken AS f
    JOIN salon_afspraak_regels AS r ON f.salon_afspraak_id = r.salon_afspraak_id
    JOIN salon_afspraak_regel_producten AS p ON r.salon_afspraak_regel_id = p.salon_afspraak_regel_id
    WHERE NOT f.administratie_kosten IS NULL AND f.administratie_kosten > 0
    GROUP BY f.salon_afspraak_id, f.administratie_kosten
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
      INSERT INTO salon_afspraak_regel_producten(salon_afspraak_regel_id, product_naam, product_btw, product_prijs, product_aantal) VALUES(v_first_factuur_regel_id, 'Administratiekosten', 19, v_administratie_kosten, 1);
    END IF;
  END LOOP the_loop;

  CLOSE facturen_cursor;

END;