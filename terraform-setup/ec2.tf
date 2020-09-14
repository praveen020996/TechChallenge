data "template_file" "client" {
  template = file("./userdata.sh")
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash -xe
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    yum update -y
    yum install python3 -y
    curl -O https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py --user
    export PATH=~/.local/bin:$PATH
    pip3 install awscli --upgrade
    aws configure set aws_access_key_id "${var.aws_access_key_id}"
    aws configure set aws_secret_access_key "${var.aws_secret_access_key}"
    aws configure set default.region "${var.aws_region}"
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    cp ./kubectl /usr/local/bin
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    aws eks --region "${var.aws_region}" update-kubeconfig --name "${aws_eks_cluster.cluster.name}"
    echo 'export PATH=$PATH:$HOME/bin' >> ~/.bash_profile
    mkdir -p /home/ec2-user/workspace
    cd /home/ec2-user/workspace
    yum install golang -y
    mkdir -p $HOME/go/bin
    export GOPATH=$HOME/go
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
    yum install docker -y
    yum install git -y
    go get -d github.com/servian/TechChallengeApp
    cd /go/src/github.com/servian/TechChallengeApp
    sed -i '$d' Dockerfile
    echo 'ENTRYPOINT [ "./TechChallengeApp","serve" ]' >> Dockerfile
    yum install jq -y
    username=$(aws secretsmanager get-secret-value --secret-id "${aws_secretsmanager_secret.secret.id}" --region "${var.aws_region}" | jq --raw-output .SecretString | jq -r ."dbuser")
    password=$(aws secretsmanager get-secret-value --secret-id "${aws_secretsmanager_secret.secret.id}" --region "${var.aws_region}" | jq --raw-output .SecretString | jq -r ."dbpassword")
    endpoint=$(aws secretsmanager get-secret-value --secret-id "${aws_secretsmanager_secret.secret.id}" --region "${var.aws_region}" | jq --raw-output .SecretString | jq -r ."dbendpoint")
    export VTT_DBUSER=$username
    export VTT_DBPASSWORD=$password
    export VTT_DBNAME="postgres"
    export VTT_DBPORT="5432"
    export VTT_DBHOST=$endpoint
    export VTT_LISTENHOST="0.0.0.0"
    export VTT_LISTENPORT="80"
    if [ -d "dist" ]; then
    rm -rf dist
    fi
    mkdir -p dist
    sudo go mod tidy
    sudo go build -o TechChallengeApp .
    cp TechChallengeApp dist/
    cp -r assets dist/
    cp conf.toml dist/
    rm TechChallengeApp
    ./dist/TechChallengeApp updatedb -s
    service docker start
    docker build -t techchallenge:v1 .
    aws ecr get-login-password --region "${var.aws_region}" | docker login --username AWS --password-stdin "${aws_ecr_repository.registry.repository_url}"
    docker tag techchallenge:v1 "${aws_ecr_repository.registry.repository_url}"
    docker push "${aws_ecr_repository.registry.repository_url}"
    cd /home/ec2-user
    git clone https://github.com/praveen020996/TechChallenge.git
    cd TechChallenge/kubernetes-manifests
    repository_name="${aws_ecr_repository.registry.name}"
    registry_id="${aws_ecr_repository.registry.registry_id}"
    region="${var.aws_region}"
    sed -i "s/{{repo_name}}/$repository_name/g" deployment.yaml
    sed -i "s/{{registry_id}}/$registry_id/g" deployment.yaml
    sed -i "s/{{region}}/$region/g" deployment.yaml
    sudo /kubectl config view
    sudo /kubectl create secret generic dbcreds \
        --from-literal=dbendpoint=$endpoint \
        --from-literal=dbusername=$username \
        --from-literal=dbpassword=$password \
        --from-literal=dbname=postgres \
        --from-literal=dbport=5432 \
        --from-literal=listenerhost=0.0.0.0 \
        --from-literal=listenerport=80
    sudo /kubectl apply -f deployment.yaml
    sudo /kubectl apply -f service.yaml
    EOF
  }
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.client.rendered
  }
}

data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners      = ["amazon"]
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.*.id[0]
  user_data = data.template_cloudinit_config.config.rendered
  
  tags = {
    Name = "EKS Workspace"
  }
}

