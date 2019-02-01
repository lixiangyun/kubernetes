#! /bin/bash

export CLUSTER_IDX=0
export DEPLOY_IDX=1

export CSE_NODE1=10.x.x.10
export CSE_NODE2=10.x.x.20
export CSE_NODE3=10.x.x.30

# port+x: 2370-2079 / 2380-2389
export DATA_PORT=2370
export PEER_PORT=2380

function show_help()
{
    echo "********************************************************"
    echo "* [OPTION]                                             *"
    echo "*   -c <0|1|...|9>     #cluster index (default:0)      *"
    echo "*   -d <1|2|3>         #deploy node index(default:1)   *"
    echo "********************************************************"
	exit 1
}

function parse_input()
{
    while getopts c:d:h OPTION
    do
    case $OPTION in
        c) CLUSTER_IDX=$OPTARG
        ;;
        d) DEPLOY_IDX=$OPTARG
		;;
        h)show_help
        ;;
        \?)show_help
        ;;
        esac
    done
}

parse_input $@

if [ $DEPLOY_IDX == "1" ] ;then
	LOCAL_NODE=$CSE_NODE1
elif [ $DEPLOY_IDX == "2" ] ;then
	LOCAL_NODE=$CSE_NODE2
elif [ $DEPLOY_IDX == "3" ] ;then
	LOCAL_NODE=$CSE_NODE3
else
	show_help
fi

export DATA_PORT=237$CLUSTER_IDX
export PEER_PORT=238$CLUSTER_IDX
export ETCD_NAME=cse-etcd-$CLUSTER_IDX-$DEPLOY_IDX
export ETCD_NODE1=cse-etcd-$CLUSTER_IDX-1
export ETCD_NODE2=cse-etcd-$CLUSTER_IDX-2
export ETCD_NODE3=cse-etcd-$CLUSTER_IDX-3
export ETCD_CLUSTER_IP="$ETCD_NODE1=http://$CSE_NODE1:$PEER_PORT,$ETCD_NODE2=http://$CSE_NODE2:$PEER_PORT,$ETCD_NODE3=http://$CSE_NODE3:$PEER_PORT"
export ETCD_CLUSTER_NAME=cse-etcd-cluster-$CLUSTER_IDX
export ETCD_DATA=/opt/etcd/$ETCD_NAME

echo "*******************DEPLOY INFO************************"
echo ""
echo " LOCAL NODE : $LOCAL_NODE"
echo " NODE LIST  : $CSE_NODE1 $CSE_NODE2 $CSE_NODE3"
echo ""
echo " ETCD NAME     : $ETCD_NAME"
echo " ETCD PORT     : http://$LOCAL_NODE:$DATA_PORT"
echo "                 http://$LOCAL_NODE:$PEER_PORT"
echo " DATA PATH     : $ETCD_DATA"
echo ""
echo " ETCD CLUSTER      : $ETCD_CLUSTER_NAME"
echo " ETCD CLUSTER LIST : $ETCD_CLUSTER_IP"
echo ""
echo "*******************************************************"

docker rm -f $ETCD_NAME

docker run --net=host -d --restart=always \
    -v $ETCD_DATA:/opt/etcd \
	--name $ETCD_NAME \
	quay.io/coreos/etcd \
	/usr/local/bin/etcd \
	-name $ETCD_NAME \
	-data-dir /opt/etcd \
	-advertise-client-urls http://$LOCAL_NODE:$DATA_PORT \
	-listen-client-urls http://0.0.0.0:$DATA_PORT \
	-initial-advertise-peer-urls http://$LOCAL_NODE:$PEER_PORT \
	-listen-peer-urls http://0.0.0.0:$PEER_PORT \
	-initial-cluster-token $ETCD_CLUSTER_NAME \
	-initial-cluster $ETCD_CLUSTER_IP \
	-initial-cluster-state new
