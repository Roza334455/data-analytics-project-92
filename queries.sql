age_groups
/* 
 1. Выбираем возраст
 2. Добавляем категорию для NULL или некорректных значений
 3. Используем COUNT(*), чтобы учитывать все строки
 4. Исключаем записи с NULL в возрасте
 5. Явно указываем имя столбца для группировки
 6. Сортируем по категории возраста
*/
SELECT 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16–25'
        WHEN age BETWEEN 26 AND 40 THEN '26–40'
        WHEN age > 40 THEN '40+'
        ELSE 'Unknown'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers c
WHERE age IS NOT NULL
GROUP BY age_category
ORDER BY age_category;


customers_by_month
/* 
 1. Создали временную таблицу с именем tab, которая содержит данные о клиентах, дате продажи, цене продукта и 
 количестве проданных единиц
 2. Преобразуем дату продажи в формат "год-месяц", подсчитываем количество уникальных клиентов за каждый месяц,
 вычисляем доход за каждый месяц
 3. Группируем данные по месяцам и сортируем в порядке возрастания месяцев
*/
WITH tab AS (
   SELECT
       c.customer_id,
       s.sale_date,
       p.price,
       s.quantity
   FROM customers c
   JOIN sales s ON c.customer_id = s.customer_id
   JOIN products p ON s.product_id = p.product_id
)
SELECT
   TO_CHAR(sale_date, 'YYYY-MM') AS selling_month,
   COUNT(DISTINCT customer_id) AS total_customers,
   FLOOR(SUM(price * quantity)) AS income
FROM tab
GROUP BY TO_CHAR(sale_date, 'YYYY-MM')
ORDER BY TO_CHAR(sale_date, 'YYYY-MM');


special_offer
/* 
 1. Создали временную таблицу, в ней выбираем id покупателя, полное имя покупателя, минимальную дату продажи 
 и полное имя продавца
 2. Выбираем только те продажи, где цена продукта равна нулю
 3. Группируем данные по покупателям и продавцам
 4. В основном запросе мы фильтруем строки из tab, оставляя только те, где 
дата продажи совпадает с первой датой продажи для данного покупателя
 5. Результат сортируется по имени покупателя
*/
WITH tab AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer,
        MIN(s.sale_date) AS sale_date,
        CONCAT(e.first_name, ' ', e.last_name) AS seller
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    WHERE p.price = 0
    GROUP BY 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name),
        CONCAT(e.first_name, ' ', e.last_name)
)
SELECT
    t.customer,
    t.sale_date,
    t.seller
FROM tab t
WHERE t.sale_date IN (
    SELECT MIN(sale_date)
    FROM sales
    GROUP BY customer_id
)
ORDER BY t.customer;


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