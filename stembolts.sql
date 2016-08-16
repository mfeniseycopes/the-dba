CREATE TABLE stembolts (
  id INTEGER PRIMARY KEY,
  color VARCHAR(255) NOT NULL,
  officer_id INTEGER,

  FOREIGN KEY(officer_id) REFERENCES officer(id)
);

CREATE TABLE officers (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  ship_id INTEGER,

  FOREIGN KEY(ship_id) REFERENCES officer(id)
);

CREATE TABLE ships (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

INSERT INTO
  ships (id, name)
VALUES
  (1, "Enterprise"), (2, "Voyager");

INSERT INTO
  officers (id, fname, lname, ship_id)
VALUES
  (1, "Geordi Laforge", 1),
  (2, "Belanna Torres", 1);

INSERT INTO
  stembolts (id, name, officer_id)
VALUES
  (1, "Blue", 1),
  (2, "Green", 2),
  (3, "Grey", 2),
  (4, "Yellow", 2);
