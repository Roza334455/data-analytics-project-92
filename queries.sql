top_10_total_income
/*
Этот запрос указывает полное имя продавца, количество операций, округленный доход, 
соединяет таблицы: "сотрудники" и "продажи", "продажи" и "продукты", делает группировку 
по ID сотрудника и его имени, сортировку по доходу в порядке убывания, ограничивает 
результат первыми 10 записями
*/
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM
    employees e
INNER JOIN 
    sales s ON e.employee_id = s.sales_person_id
INNER JOIN
    products p ON s.product_id = p.product_id
GROUP BY
    e.employee_id, CONCAT(e.first_name, ' ', e.last_name)
ORDER BY 
    income DESC
LIMIT 10;


lowest_average_income
/* 
 1. Вычислить средний доход для каждого продавца
 2. Ищем общий средний доход по всем продавцам
 3. Выбираем продавцов с доходом ниже общего среднего
*/
WITH average_income AS (
    SELECT 
        s.sales_person_id,
        FLOOR(SUM(s.quantity * p.price) / COUNT(s.sales_id)) AS avg_income
    FROM 
        sales s
    INNER JOIN products p ON s.product_id = p.product_id
    GROUP BY s.sales_person_id
),
overall_average AS (
    SELECT 
        FLOOR(AVG(avg_income)) AS overall_avg
    FROM 
        average_income
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ai.avg_income AS average_income
FROM 
    average_income ai
INNER JOIN employees e ON ai.sales_person_id = e.employee_id
WHERE 
    ai.avg_income < (SELECT overall_avg FROM overall_average)
ORDER BY 
    ai.avg_income ASC;


day_of_the_week_income
/* 
 1. Выбираем продавца, день недели и округленный доход за этот день
 2. Соединяем таблицы employee и sales, sales и products
 3. Группировка по: порядковому номеру дня недели, имени продавца, дню недели
 4. Сортировка по: порядковому номеру дня недели, имени продавца
*/
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TO_CHAR(s.sale_date, 'day') AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM
    employees e
INNER JOIN sales s ON e.employee_id = s.sales_person_id
INNER JOIN products p ON s.product_id = p.product_id
GROUP BY 
    EXTRACT(ISODOW FROM s.sale_date),
    CONCAT(e.first_name, ' ', e.last_name),
    TO_CHAR(s.sale_date, 'day')
ORDER BY 
    EXTRACT(ISODOW FROM s.sale_date),
    seller;