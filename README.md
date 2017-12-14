# Importio
Аналіз структури проектів для Flow.<br>
ОС: Windows, Linux.

## Installation
Виконайте наступні дії:
1. Встановлюємо Erlang OTP: http://www.erlang.org/downloads (спробуйте запустити escript, має видати в консоль - escript: Missing filename).
2. Встановлюємо http://www.graphviz.org/Download.php і перевіряємо чи виконується dot.exe -v (Windows) або dot -v (Linux).
3. Скачуємо [zip архів](https://github.com/Karkunow/import.io/blob/master/import.io.zip) і копіюємо вміст в будь-яке зручне місце.
4. Налаштовуємо на неї зручний alias в WAMP сервері.
5. Запускаємо потрібною командою за допомогою escript importio з даної папки.
6. Переглядаємо результати на сервері:
  http://127.0.0.1/importio/ + tree.html або graph.html.
7. Або переглядаємо graph.jpeg файл в папці import.io\data побудований утилітою dot.

## Script configurations

Якщо коротко, то опції в нас наступні:
Повні назви:
* --root_folders :string — список кореневих папок через кому, наприклад - "C:\root_folder1, C:\folder\root_folder2"
* --file :string —  назва файлу для аналізу - myproject/reports/main, 
* --inner_search :boolean — проводити аналіз імпортів тільки в папці кореневого файлу, для 	прикладу згори це — myproject/reports/. Корисна опція для початку аналіза та оптимізації свого проекта.
* --graph :boolean — побудувати дані у вигляді графа,
* --tree :boolean — побудувати дані у вигляді дерева,
* --dot :boolean — побудувати дані у вигляді графа з ефективним layout'ом,
* --depth :integer — максимальна глибина проходу по імпортам,
* --cleaned_level :integer — максимальна глибина видалення зайвих імпортів,
* --cleanup :boolean — увімкнути авто-видалення зайвих імпортів,

Відповідні короткі назви (aliases):
* -rf для --root_folders,
* -f  для --file,
* -oi для --inner_search,
* -dp для --depth,
* -cl для --cleaned_level;

## Examples

* Очищення зайвих імпортів до глибини 3: <br>`escript importio -rf "C:\flowapps, C:\flow\lib" -f myproject/reports/main -dp 5 --cleanup -cl 3`
* Побудова дерева: <br>`escript importio -rf "C:\sports, C:\flow\lib, C:\material" -f myproject/reports/main -dp 5 --tree`
* Побудова інтерактивного графа: <br>`escript importio -rf "C:\flowapps, C:\flow\lib" -f adminpanel/main -dp 6 -oi --graph`
* Побудова графа імпортів з ефективним layout'ом в .jpeg: <br>`escript importio -rf "C:\flowapps, C:\flow\lib" -f adminpanel/main -dp 6 --dot`

## More info

Головна ціль програми — це аналіз структури проекту по імпортам в ньому. Є декілька варіантів дослідження:
1. Намалювати інтерактивний граф зв'язків (для невеликих проектів):
![Приклад графу](https://github.com/Karkunow/import.io/blob/master/img/1.png)
2. Намалювати інтерактивне дерево (для малих та середніх проектів, для великих - ефективне відображення регулюється глибиною проходу по папкам):
![Приклад дерева](https://github.com/Karkunow/import.io/blob/master/img/2.png)
* **Червоним** в ньому позначені “важкі” модулі, імпорти в яких потребують впорядкування та декомпозування — їх просто занадто багато!
* **Жовтим** позначені ті імпорти, які можна видалити, бо вони вже десь зустрічаються глибше (вручну або автоматично за допомогою параметра —cleanup). При наведені на жовту вершину ви побачите попап з інформацією де саме цей імпорт повторюється.
* **Синім** — модулі, які мають імпорти.
* **Білим\Світложовтим** — кінцеві модулі, листя нашого дерева.

3. Ефективно намалювати граф зв'язків і зберегти рез-тат в jpeg файл для перегляду:
![Приклад Jpeg](https://github.com/Karkunow/import.io/blob/master/img/3.png)
Якби це парадоксально не здавалося, судячи з картинки вище, але це дуже ефективний спосіб оцінити весь проект на око. Відчуваєш себе географом\дослідником, що розглядає карту :) Дуже чітко видно перевантажені модулі і на що потрібно звернути увагу.
