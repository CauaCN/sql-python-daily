WITH backups_semanais AS
  (SELECT database_name,
          DATEPART(YEAR, backup_finish_date) AS ano,
          DATEPART(WEEK, backup_finish_date) AS semana,
          MAX(backup_finish_date) AS ultima_data,
          MAX(backup_size) AS tamanho_bytes
   FROM msdb.dbo.backupset
   WHERE TYPE = 'D'
     AND backup_finish_date IS NOT NULL
     AND backup_finish_date >= DATEADD(MONTH, -3, GETDATE())
   GROUP BY database_name,
            DATEPART(YEAR, backup_finish_date),
            DATEPART(WEEK, backup_finish_date)),
     com_lag AS
  (SELECT database_name,
          ano,
          semana,
          ultima_data,
          tamanho_bytes,
          tamanho_bytes / 1024.0 / 1024 / 1024 AS tamanho_gb,
          LAG(tamanho_bytes) OVER (PARTITION BY database_name
                                   ORDER BY ano, semana) AS tamanho_anterior_bytes
   FROM backups_semanais)
SELECT database_name,
       ano,
       semana,
       FORMAT(ultima_data, 'dd/MM/yyyy') AS ultima_data,
       CAST(ROUND(tamanho_gb, 2) AS DECIMAL(10, 2)) AS tamanho_atual_gb,
       CASE
           WHEN tamanho_anterior_bytes IS NULL THEN 'Sem backup anterior'
           WHEN tamanho_bytes = tamanho_anterior_bytes THEN 'Sem crescimento'
           WHEN tamanho_bytes > tamanho_anterior_bytes THEN CONCAT('+', CAST(ROUND((tamanho_bytes - tamanho_anterior_bytes) * 100.0 / tamanho_anterior_bytes, 2) AS DECIMAL(10, 2)), '% (+ ', CAST(ROUND((tamanho_bytes - tamanho_anterior_bytes) / 1024.0 / 1024 / 1024, 3) AS DECIMAL(10, 3)), ' GB)')
           ELSE CONCAT(CAST(ROUND((tamanho_bytes - tamanho_anterior_bytes) * 100.0 / tamanho_anterior_bytes, 2) AS DECIMAL(10, 2)), '% (- ', CAST(ROUND(ABS(tamanho_bytes - tamanho_anterior_bytes) / 1024.0 / 1024 / 1024, 3) AS DECIMAL(10, 3)), ' GB)')
       END AS variacao
FROM com_lag
WHERE tamanho_anterior_bytes IS NOT NULL
  AND tamanho_bytes != tamanho_anterior_bytes
ORDER BY database_name, ano, semana;
