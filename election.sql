-- The following are queries and test cases for the election project. 
-- For more information about the assignment details, problem set, and solutions, please view the pdf in the repository


-- 1.1 

DROP PROCEDURE IF EXISTS API1;


DELIMITER $$
CREATE PROCEDURE API1(IN C VARCHAR(30), IN T DATETIME, IN P VARCHAR(100), OUT V INT)
BEGIN
    DECLARE lastvote INT;
    DECLARE tvoteprime INT;
    DECLARE tvote INT;
    
    IF ( strcmp(C,"Biden" ) <> 0 AND strcmp(C, "Trump") <> 0)THEN
        SELECT "incorrect candidate";
        END IF;
    IF NOT EXISTS (SELECT DISTINCT Penna.precinct FROM Penna WHERE P = Penna.precinct) THEN
        SELECT "incorrect precinct";
        END IF;

    SELECT
    CASE
        WHEN C = 'Biden' THEN Penna.Biden
        WHEN C = 'Trump' THEN Penna.Trump
    END AS can
    INTO lastvote
    FROM testDB.Penna
    WHERE Penna.precinct = P AND Penna.Timestamp = (SELECT MAX(Penna.Timestamp)) LIMIT 1;
    
    SELECT Penna.totalvotes INTO tvoteprime
    FROM testDB.Penna
    WHERE Penna.precinct = P AND  Penna.Timestamp = (SELECT MAX(Penna.Timestamp) WHERE Penna.Timestamp < T) LIMIT 1; 

    SELECT 
    CASE
        WHEN C = 'Biden' THEN Penna.Biden
        WHEN C = 'Trump' THEN Penna.Trump
    END AS votes
    INTO tvote
    FROM testDB.Penna
    WHERE Penna.precinct = P AND Penna.Timestamp = T;

    IF T < (SELECT MIN(Penna.Timestamp) FROM Penna) THEN SET V = 0;
    ELSEIF T > (SELECT MAX(Penna.Timestamp) FROM Penna) THEN SET V = lastvote;
    ELSEIF T IN (SELECT Penna.Timestamp FROM Penna) THEN SET V = tvote;
    ELSE SET V = tvoteprime;
    END IF;
END $$
DELIMITER ;

-- 1.1 TEST

SET @myfirstoutput = 0;
CALL API1('Biden', '2020-11-07 03:01:22', 'Adams Township - Dunlo Voting Precinct', @myfirstoutput);
SELECT @myfirstoutput;

-- 1.2

DROP PROCEDURE IF EXISTS API2;
DELIMITER $$
CREATE PROCEDURE API2(IN T DATE)
BEGIN


SELECT 
CASE WHEN 
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )
    THEN 'Biden'
    ELSE 'Trump'
END AS candidate,
CASE WHEN 
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )
    THEN SUM(Penna.Biden)
    ELSE SUM(Penna.Trump)
END AS votes
FROM Penna
WHERE Penna.Timestamp = (SELECT MAX(Penna.Timestamp) FROM Penna WHERE DATE(Penna.Timestamp) = '2020-11-06');
END $$
DELIMITER ;

-- 1.2 TEST

CALL API2('2020-11-06');

-- 1.3

DROP PROCEDURE IF EXISTS API3;

DELIMITER $$
CREATE PROCEDURE API3(IN C VARCHAR(30))
BEGIN

IF ( strcmp(C,"Biden" ) <> 0 AND strcmp(C, "Trump") <> 0)THEN
SELECT "incorrect candidate";
END IF;
        
IF C = 'Biden' 
THEN 
(SELECT Penna.precinct, Penna.totalvotes
FROM Penna
WHERE Penna.Biden > (Penna.totalvotes / 2) AND DATE(Penna.Timestamp) = '2020-11-11'
GROUP BY Penna.precinct, Penna.totalvotes
ORDER BY Penna.totalvotes DESC LIMIT 10);
ELSE 
(SELECT Penna.precinct, Penna.totalvotes
FROM Penna
WHERE Penna.Trump > (Penna.totalvotes / 2) AND DATE(Penna.Timestamp) = '2020-11-11'
GROUP BY Penna.precinct, Penna.totalvotes
ORDER BY Penna.totalvotes DESC LIMIT 10);
END IF;
END $$
DELIMITER ;

-- 1.3 TEST

CALL API3('Biden');

-- 1.4

DROP PROCEDURE IF EXISTS API4;
DELIMITER $$
CREATE PROCEDURE API4(IN P VARCHAR(150))
BEGIN
 
 IF NOT EXISTS (SELECT DISTINCT Penna.precinct FROM Penna WHERE P = Penna.precinct) THEN
        SELECT "incorrect precinct";
        END IF;
SELECT 
    CASE WHEN 
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )
    THEN 'Biden'
    ELSE 'Trump'
    END AS candidate,

    CASE WHEN 
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )
    THEN (SUM(Penna.Biden) / SUM(Penna.totalvotes) * 100)
    ELSE (SUM(Penna.Trump) / SUM(Penna.totalvotes) * 100)
    END AS percent
FROM Penna
WHERE Penna.precinct = P;
END $$
DELIMITER ;

-- 1.4 TEST

CALL API4('Adams Township - Elton Voting Precinct');

-- 1.5

DROP PROCEDURE IF EXISTS API5;
DELIMITER $$
CREATE PROCEDURE API5(IN P VARCHAR(150))
BEGIN
    SELECT
    CASE WHEN
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )
    THEN 'Biden'
    ELSE 'Trump'
END AS candidate,
    CASE WHEN
    (
        SUM(Penna.Biden) > SUM(Penna.Trump)
    )   
    THEN SUM(Penna.Biden)
    ELSE SUM(Penna.Trump)
END AS votes
FROM Penna
WHERE (SELECT(LOCATE(P, Penna.precinct) <> 0));
END $$
DELIMITER ;

-- 1.5 TEST

CALL API5('Township');


-- 2.1

CREATE TABLE newPenna
(   
    new_Precinct VARCHAR(45),
    new_Timestamp DATETIME,
    new_Votes INT,
    new_Biden INT,
    new_Trump INT
);

INSERT INTO newPenna(new_Precinct,new_Timestamp)
SELECT Penna.precinct, Penna.Timestamp
FROM Penna;

DROP PROCEDURE IF EXISTS newPenna;
DELIMITER $$
CREATE PROCEDURE newPenna()
BEGIN
DECLARE var_count int DEFAULT 0;
DECLARE var_end_count int DEFAULT 0;
DECLARE P VARCHAR(150);
DECLARE T DATETIME;

DECLARE cur CURSOR FOR
SELECT newPenna.new_Precinct, newPenna.new_Timestamp
FROM newPenna;



SET var_count = 0;
SELECT count(*) INTO var_end_count FROM newPenna;

OPEN cur;

WHILE var_count < var_end_count DO
FETCH NEXT FROM cur INTO P, T;
INSERT INTO newPenna(new_Votes, newBiden, newTrump)
SELECT Penna.totalvotes - 
(SELECT Penna.totalvotes 
FROM Penna 
WHERE Penna.Timestamp = 
(SELECT MAX(Penna.Timestamp) WHERE Penna.Timestamp < T) LIMIT 1), 
Penna.Biden - (SELECT Penna.Biden
FROM Penna 
WHERE Penna.Timestamp = 
(SELECT MAX(Penna.Timestamp) WHERE Penna.Timestamp < T) LIMIT 1),
Penna,Trump - (SELECT Penna.Trump
FROM Penna 
WHERE Penna.Timestamp = 
(SELECT MAX(Penna.Timestamp) WHERE Penna.Timestamp < T) LIMIT 1)
FROM Penna
WHERE Penna.precinct = P AND Penna.Timestamp = T;

SET var_count = var_count + 1;
END WHILE;
CLOSE cur;
END $$
DELIMITER ;



CALL newPenna();


-- 2.2

SELECT p1.precinct
FROM ( SELECT * FROM Penna WHERE Penna.Timestamp > '2020-11-11 00:00:00') AS p1,
( SELECT * FROM Penna WHERE Penna.Timestamp > '2020-11-11 00:00:00') AS p2
WHERE p1.precinct = p2.precinct AND p1.Trump > p1.Biden AND p2.Trump < p2.Biden 
UNION
SELECT p1.precinct
FROM ( SELECT * FROM Penna WHERE Penna.Timestamp > '2020-11-11 00:00:00') AS p1,
( SELECT * FROM Penna WHERE Penna.Timestamp > '2020-11-11 00:00:00') AS p2
WHERE p1.precinct = p2.precinct AND p1.Trump < p1.Biden AND p2.Trump > p2.Biden;


-- 2.3

-- A —-

SELECT
    CASE WHEN NOT EXISTS
    (
        SELECT Penna.ID
        FROM Penna
        GROUP BY Penna.ID
        HAVING (SUM(Penna.Biden) + SUM(Penna.Trump)) > SUM(Penna.totalvotes)
    )
    THEN 'TRUE'
    ELSE 'FALSE'
END;

-- B —-

SELECT
    CASE WHEN NOT EXISTS
    (
        SELECT * 
        FROM Penna
        WHERE DATE(Penna.Timestamp) < '2020-11-03' OR DATE(Penna.Timestamp) > '2020-11-11'
    )
    THEN 'TRUE'
    ELSE 'FALSE'
END;

-- C —-

SELECT
    CASE WHEN NOT EXISTS
    (
        SELECT *
        FROM 
        (
        SELECT Penna.totalvotes as tvotes,
        LEAD(totalvotes) OVER(ORDER BY totalvotes) as next_vote_count
        FROM Penna
        WHERE DATE(Penna.Timestamp) = '2020-11-05' 
        ) as data
        WHERE next_vote_count < tvotes
    )
    THEN 'TRUE'
    ELSE 'FALSE'
END;

-- 4.1 update

SET SQL_SAFE_UPDATES = 0;

DROP TABLE IF EXISTS Updated_Tuples;
CREATE TABLE Updated_Tuples LIKE Penna;

DROP TABLE IF EXISTS Inserted_Tuples;
CREATE TABLE Inserted_Tuples LIKE Penna;

DROP TABLE IF EXISTS Deleted_Tuples;
CREATE TABLE Deleted_Tuples LIKE Penna;

DROP TRIGGER update_op;
DELIMITER $$
CREATE TRIGGER update_op BEFORE UPDATE ON Penna
FOR EACH ROW
BEGIN
INSERT INTO Updated_Tuples
SELECT * FROM Penna
WHERE Penna.ID = OLD.ID AND Penna.Timestamp = OLD.Timestamp;
END  $$
DELIMITER ;

-- TEST update

SELECT *
FROM Updated_Tuples;

DESCRIBE Penna;



UPDATE Penna
SET Penna.state = 'NJ'
WHERE Penna.ID = 1 AND Penna.Timestamp = '2020-11-04 03:58:36';

SELECT *
FROM Penna
WHERE Penna.ID = 1;


-- 4.1 insert

DROP TRIGGER insert_op;
DELIMITER $$
CREATE TRIGGER insert_op AFTER INSERT ON Penna
FOR EACH ROW
BEGIN
INSERT INTO Inserted_Tuples
VALUES(NEW.ID, NEW.Timestamp, NEW.state, NEW.locality, NEW.precinct, NEW.geo, NEW.totalvotes,NEW.Biden, NEW.Trump, NEW.filestamp);
END  $$
DELIMITER ;

-- TEST insert

INSERT INTO Penna
VALUES (1, '2020-11-04 03:58:35', 'NJ', 'Middlesex', 'Monroe Twp.', '42021-MON TWP', 35, 30, 5, 'NOVEMBER_04_2020_013100.json');

SELECT *
FROM Inserted_Tuples;

-- 4.1 delete

DROP TRIGGER delete_op;
DELIMITER $$
CREATE TRIGGER delete_op BEFORE DELETE ON Penna
FOR EACH ROW
BEGIN
INSERT INTO Deleted_Tuples
SELECT * FROM Penna
WHERE Penna.ID = OLD.ID AND Penna.Timestamp = OLD.Timestamp;
END  $$
DELIMITER ;

-- TEST delete

DELETE FROM Penna
WHERE Penna.precinct = 'Monroe Twp.';

SELECT *
FROM Deleted_Tuples;

SELECT *
FROM Penna
WHERE Penna.precinct = 'Monroe Twp.';


-- 4.2

SELECT *
FROM Penna
WHERE Penna.precinct = 'Red Hill' AND Penna.Timestamp = '2020-11-06 15:38:36';

DELIMITER $$
CREATE PROCEDURE MoveVotes(
    IN P VARCHAR(150),
    IN T TIMESTAMP,
    IN C VARCHAR(100),
    IN Moved_vote INT)
BEGIN

    IF ( strcmp(C,"Biden") <> 0 AND strcmp(C, "Trump") <> 0 )THEN
        SELECT "incorrect candidate";
    END IF;
    IF NOT EXISTS (SELECT DISTINCT Penna.precinct FROM Penna WHERE P = Penna.precinct) THEN
        SELECT "incorrect precinct";
    END IF;
    IF NOT EXISTS (SELECT DISTINCT Penna.Timestamp FROM Penna WHERE T = Penna.Timestamp) THEN
        SELECT "incorrect timestamp";
    END IF;
    IF strcmp(C, "Biden") = 0 THEN
        UPDATE Penna
        SET 
            Penna.Biden = Penna.Biden - Moved_vote,
            Penna.Trump = Penna.Trump + Moved_vote
        WHERE Penna.precinct = P and Penna.Timestamp= T;
    END IF;
    IF strcmp(C, "Trump") = 0 THEN
        UPDATE Penna
        SET 
            Penna.Biden = Penna.Biden + Moved_vote,
            Penna.Trump = Penna.Trump - Moved_vote
        WHERE Penna.precinct = P AND Penna.Timestamp = T;
    END IF;
END;
DELIMITER ;