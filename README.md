# Importio
Аналіз структури проектів для Flow.<br>
ОС: Windows, Linux.

## Installation
Виконайте наступні дії:
1. Встановлюємо Erlang OTP: http://www.erlang.org/downloads (спробуйте запустити escript, має видати в консоль - escript: Missing filename).
2. Встановлюємо http://www.graphviz.org/Download.php і перевіряємо чи виконується dot.exe -v (Windows) або dot -v (Linux).
2. Копіюємо папку import.io в будь яке зручне місце.
3. Налаштовуємо на неї зручний alias в WAMP сервері.
4. Запускаємо потрібною командою за допомогою escript importio з даної папки.
5. Переглядаємо результати на сервері:
  http://127.0.0.1/importio/ + tree.html або graph.html.
6. Або переглядаємо graph.jpeg файл в папці importio\data побудований утилітою dot.

## Script configurations

Якщо коротко, то опції в нас наступні:
Повні назви:
* --root_folders :string — список кореневих папок через кому, наприклад - "C:\sports, C:\flow\lib, C:\material"
* --file :string —  назва файлу для аналізу - smartbuilder/reports/reporter/main, 
* --inner_search :boolean — проводити аналіз імпортів тільки в папці кореневого файлу, для 	прикладу згори це — smartbuilder/reports/reporter/. Корисна опція для початку аналіза та оптимізації свого проекта.
* --graph :boolean — побудувати дані у вигляді графа,
* --tree :boolean — побудувати дані у вигляді дерева,
* --dot :boolean — побудувати дані у вигляді графа з ефективним layout'ом,
* --depth :integer — максимальна глибина проходу по імпортам,
* --cleaned_level :integer — максимальна глибина очищення імпортів,
* --cleanup :boolean — увімкнути авто-очищення імпортів,

Відповідні короткі назви (aliases):
* -rf для --root_folders,
* -f  для --file,
* -oi для --inner_search,
* -dp для --depth,
* -cl для --cleaned_level;
