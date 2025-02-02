#!/bin/bash

cd /home/ubuntu
tee -a install.sh > /dev/null <<EOT
#!/bin/bash
apt update -y
apt install ansible -y
EOT
chmod +x install.sh
./install.sh

tee -a playbook.yml > /dev/null <<EOT
- hosts: localhost
  tasks:
  
  - name: Instalando o python3, virtualenv
    apt:
      pkg:
      - python3
      - virtualenv
      update_cache: yes
    become: yes

  - name: Clone Git
    ansible.builtin.git:
      repo: https://github.com/guilhermeonrails/clientes-leo-api.git
      dest: /home/ubuntu/tcc
      version: master
      force: yes  

  - name: Instalando dependências com pip ( podemos trocar o nome da tarefa)
    pip:
      virtualenv: /home/ubuntu/tcc/venv
      requirements: /home/ubuntu/tcc/requirements.txt

  - name: Alterando o hosts do settings
    lineinfile:
      path: /home/ubuntu/tcc/setup/settings.py
      regexp: 'ALLOWED_HOSTS'
      line: 'ALLOWED_HOSTS = ["*"]'
      backrefs: yes 

  - name: Configurando o banco de dados
    shell: '. /home/ubuntu/tcc/venv/bin/activate; python /home/ubuntu/tcc/manage.py migrate'

  - name: Carregando os dados iniciais
    shell: '. /home/ubuntu/tcc/venv/bin/activate; python /home/ubuntu/tcc/manage.py loaddata clientes.json'

  - name: Iniciando o Servidor
    shell:    '. /home/ubuntu/tcc/venv/bin/activate; nohup python /home/ubuntu/tcc/manage.py runserver 0.0.0.0:8000 &'
EOT
ansible-playbook playbook.yml