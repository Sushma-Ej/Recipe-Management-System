create database Recipe_Manager;
use Recipe_Manager;
desc recipe;
select * from Recipe;
select * from Nutritional_Info;
select * from Rating where recipe_id=1;
ALTER TABLE Recipe ADD COLUMN category VARCHAR(50);
ALTER TABLE Recipe ADD COLUMN average_rating DECIMAL(3,2) DEFAULT 0;
-- Add 'role' column to the User table so that only the admin can delete the recipes 
ALTER TABLE User ADD COLUMN role VARCHAR(50) DEFAULT 'user';
-- Set user 'admin_user' as an admin
SET SQL_SAFE_UPDATES = 0;

-- Perform the update
UPDATE User SET role = 'admin' WHERE U_name = 'admin_user';

-- Re-enable safe update mode (optional)
SET SQL_SAFE_UPDATES = 1;



-- Create the User table
CREATE TABLE User (
    U_id INT AUTO_INCREMENT PRIMARY KEY,
    U_name VARCHAR(100),
    U_password VARCHAR(100),
    email VARCHAR(100),
    U_role ENUM('admin', 'user')
);

-- Create the Recipe table
CREATE TABLE Recipe (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    prepTime INT,
    cookTime INT,
    servings INT,
    totalTime INT,
    URL VARCHAR(255),
    course VARCHAR(100),         -- Course attribute (e.g., Main Course, Appetizer)
    cuisine VARCHAR(100),        -- Cuisine attribute (e.g., Italian, Indian)
    diet VARCHAR(100),           -- Diet attribute (e.g., Vegan, Vegetarian)
	instructions TEXT,           -- Instructions for the recipe
    U_id INT,
    FOREIGN KEY (U_id) REFERENCES User(U_id)
);
ALTER TABLE Recipe ADD COLUMN rating FLOAT;

-- Create the Ingredient table
DROP TABLE IF EXISTS Ingredient;

CREATE TABLE Ingredient (
    I_id INT AUTO_INCREMENT PRIMARY KEY,
    I_name VARCHAR(255),
    quantity VARCHAR(50),
    Recipe_ID INT -- No foreign key constraint here
);


-- Create the Nutritional Info table
CREATE TABLE Nutritional_Info (
    Recipe_ID INT,
    Calories DECIMAL(5,2),
    Carbs DECIMAL(5,2),
    Proteins DECIMAL(5,2),
    Fats DECIMAL(5,2),
    PRIMARY KEY (Recipe_ID),
    FOREIGN KEY (Recipe_ID) REFERENCES Recipe(ID)
);

-- Create the Comment table
CREATE TABLE Comment (
    Com_id INT AUTO_INCREMENT PRIMARY KEY,
    text TEXT,
    User_ID INT,
    Date DATE,
    Recipe_ID INT,
    FOREIGN KEY (User_ID) REFERENCES User(U_id),
    FOREIGN KEY (Recipe_ID) REFERENCES Recipe(ID)
);

-- Create the Rating table
CREATE TABLE Rating (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    value INT,
    R_Date DATE,
    Recipe_ID INT,
    User_ID INT,
    FOREIGN KEY (Recipe_ID) REFERENCES Recipe(ID),
    FOREIGN KEY (User_ID) REFERENCES User(U_id)
);

-- Create the Recipe_Made_Of_Ingredient table (junction for Recipe and Ingredient)
CREATE TABLE Recipe_Made_Of_Ingredient (
    Recipe_ID INT,
    Ingr_ID INT,
    PRIMARY KEY (Recipe_ID, Ingr_ID),
    FOREIGN KEY (Recipe_ID) REFERENCES Recipe(ID),
    FOREIGN KEY (Ingr_ID) REFERENCES Ingredient(I_id)
);
DROP PROCEDURE IF EXISTS AddRecipeWithIngredients;

DELIMITER //

CREATE PROCEDURE AddRecipeWithIngredients(
    IN recipe_name VARCHAR(255),
    IN prep_time INT,
    IN cook_time INT,
    IN servings INT,
    IN total_time INT,
    IN url VARCHAR(255),
    IN category VARCHAR(50),
    IN course VARCHAR(50),
    IN cuisine VARCHAR(50),
    IN diet VARCHAR(50),
    IN instructions TEXT,
    IN user_id INT,
    IN ingredients TEXT  -- Expecting a string of ingredients
)
BEGIN
    DECLARE recipe_id INT;

    -- Insert into Recipe
    INSERT INTO Recipe (name, prepTime, cookTime, servings, totalTime, url, category, course, cuisine, diet, instructions, U_id)
    VALUES (recipe_name, prep_time, cook_time, servings, total_time, url, category, course, cuisine, diet, instructions, user_id);
    
    -- Get the last inserted ID
    SET recipe_id = LAST_INSERT_ID();

    -- Split the ingredients string and insert into Nutritional_Info
    -- Assume ingredients are in the format "name:quantity,name:quantity"
    SET @sql = CONCAT('INSERT INTO Ingredient (I_name, quantity, Recipe_ID) VALUES ', ingredients);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER update_average_rating
AFTER INSERT ON Rating
FOR EACH ROW
BEGIN
    DECLARE avg_rating DECIMAL(3,2);

    -- Calculate the average rating for the recipe
    SELECT AVG(rating_value) INTO avg_rating
    FROM Rating
    WHERE recipe_id = NEW.recipe_id;

    -- Update the average rating in the Recipe table
    UPDATE Recipe
    SET average_rating = avg_rating
    WHERE recipe_id = NEW.recipe_id;
END //

DELIMITER ;




ALTER TABLE Ingredient
DROP FOREIGN KEY ingredient_ibfk_1;
ALTER TABLE Ingredient
MODIFY Recipe_ID INT NULL;  -- Allow NULL values for Recipe_ID

-- Step 1: Alter the Ingredient table to enforce foreign key and non-nullable Recipe_ID
ALTER TABLE Ingredient
    MODIFY Recipe_ID INT NOT NULL,
    ADD FOREIGN KEY (Recipe_ID) REFERENCES Recipe(ID) ON DELETE CASCADE;

-- Step 2: Drop the existing procedure if it exists
DROP PROCEDURE IF EXISTS AddRecipeWithIngredients;

-- Step 3: Create the modified AddRecipeWithIngredients procedure
DELIMITER //

CREATE PROCEDURE AddRecipeWithIngredients(
    IN recipe_name VARCHAR(255),
    IN prep_time INT,
    IN cook_time INT,
    IN servings INT,
    IN total_time INT,
    IN url VARCHAR(255),
    IN course VARCHAR(50),
    IN cuisine VARCHAR(50),
    IN diet VARCHAR(50),
    IN instructions TEXT,
    IN ingredients TEXT  -- Expecting a string of ingredients
)
BEGIN
    DECLARE recipe_id INT;

    -- Insert into Recipe
    INSERT INTO Recipe (name, prepTime, cookTime, servings, totalTime, URL, category, course, cuisine, diet, instructions, U_id)
    VALUES (recipe_name, prep_time, cook_time, servings, total_time, url, category, course, cuisine, diet, instructions, user_id);
    
    -- Get the last inserted ID
    SET recipe_id = LAST_INSERT_ID();

    -- Split the ingredients string and insert into Ingredient
    SET @sql = CONCAT('INSERT INTO Ingredient (I_name, quantity, Recipe_ID) VALUES ', ingredients);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

-- Aggregated query
SELECT r.recipe_id, r.name AS recipe_name, COUNT(c.comment_id) AS comment_count
FROM Recipe r
LEFT JOIN Comment c ON r.recipe_id = c.recipe_id
GROUP BY r.recipe_id;





