# Домашнее задание к занятию «Вычислительные мощности. Балансировщики нагрузки» - Шаров Олег

## Задание 1. Yandex Cloud

### 1.1. Создание бакета Object Storage и загрузка картинки

**Код:** [yandex-cloud/main.tf](./yandex-cloud/main.tf) (блоки `yandex_storage_bucket` и `yandex_storage_object`)

**Публичная ссылка на изображение:** 
https://storage.yandexcloud.net/oleg-sharov-hw15-bucket-2026/image.jpg

**Скриншот:**
![Картинка в браузере](./yandex-cloud/screenshots/image.jpg)

---

### 1.2. Создание группы ВМ с шаблоном LAMP

**Код:** [yandex-cloud/main.tf](./yandex-cloud/main.tf) (блок `yandex_compute_instance_group`)

**Публичные IP-адреса ВМ:**
- 51.250.82.223
- 51.250.78.214
- 51.250.10.140

**Скриншоты:**
1. Список ВМ в консоли Яндекс Облака:
![Список ВМ](./yandex-cloud/screenshots/yc-vm-list.png)

2. Веб-страница Apache на одной из ВМ:
![LAMP Web Page](./yandex-cloud/screenshots/lamp-web-page.png)

3. Вывод команды terraform apply:
![Terraform Apply Output](./yandex-cloud/screenshots/terraform-apply-output.png)

---

### 1.3. Подключение группы к сетевому балансировщику и проверка отказоустойчивости

**Код:** [yandex-cloud/main.tf](./yandex-cloud/main.tf) (блоки `yandex_lb_target_group` и `yandex_lb_network_load_balancer`)

**Публичный IP балансировщика:** 51.250.83.46

**Скриншоты:**
1. Работа балансировщика (все 3 ВМ активны):
![NLB Working](./yandex-cloud/screenshots/nlb-working.png)

2. Удаление одной из ВМ через CLI:
![VM Delete](./yandex-cloud/screenshots/yc-vm-delete.png)

3. Работа балансировщика после удаления ВМ (трафик переключился на здоровые ноды):
![NLB Failover](./yandex-cloud/screenshots/nlb-working-after-vm-delete.png)

4. Автоматическое восстановление Instance Group (новая ВМ создана за 4 минуты):
![IG Auto Recovery](./yandex-cloud/screenshots/ig-auto-recovery.png)