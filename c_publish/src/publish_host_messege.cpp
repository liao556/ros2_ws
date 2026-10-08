#include <functional>
#include <memory>
#include <string>
#include <unistd.h>
#include "rclcpp/rclcpp.hpp"
#include "status_interfaces/msg/massage.hpp"
#include <chrono>
#include <fstream>
#include <sstream>
#include <iostream>
#include <thread>
//内存获取
struct MemInfo {
    float total_mb = 0.0f;       // 总内存（MB）
    float available_mb = 0.0f;   // 可用内存（MB）
};

MemInfo get_memory_info()
{
    MemInfo info;

    std::ifstream file("/proc/meminfo");
    if (!file.is_open()) {
        return info;
    }

    long long mem_total = 0;       // 单位 kB
    long long mem_available = 0;   // 单位 kB

    std::string line;
    while (std::getline(file, line)) {
        std::istringstream iss(line);
        std::string key;
        long long value;
        std::string unit;
        iss >> key >> value >> unit;

        if (key == "MemTotal:") {
            mem_total = value;
        } else if (key == "MemAvailable:") {
            mem_available = value;
        }

        if (mem_total > 0 && mem_available > 0) {
            break;
        }
    }

    info.total_mb = mem_total / 1024.0f;
    info.available_mb = mem_available / 1024.0f;

    return info;
}



//网络上传下传速度获取
struct NetBytes {
    long long sent = 0;      // 累计发送字节
    long long recv = 0;      // 累计接收字节
};

struct NetSpeed {
    float sent_bps = 0.0f;   // 上传速率，字节/秒
    float recv_bps = 0.0f;   // 下载速率，字节/秒
    float sent_kbps = 0.0f;  // 上传速率，KB/s
    float recv_kbps = 0.0f;  // 下载速率，KB/s
};

// 读取所有网卡累计字节数（跳过 lo 回环）
bool read_net_bytes(NetBytes & out)
{
    std::ifstream file("/proc/net/dev");
    if (!file.is_open()) return false;

    std::string line;
    // 跳过前两行表头
    std::getline(file, line);
    std::getline(file, line);

    long long total_sent = 0;
    long long total_recv = 0;

    while (std::getline(file, line)) {
        // 格式： eth0: 12345 678 0 0 0 0 0 0 98765 432 ...
        std::size_t colon = line.find(':');
        if (colon == std::string::npos) continue;

        std::string iface = line.substr(0, colon);
        // 去掉前后空格
        iface.erase(0, iface.find_first_not_of(" \t"));
        iface.erase(iface.find_last_not_of(" \t") + 1);

        // 跳过 lo 回环
        if (iface == "lo") continue;

        std::istringstream iss(line.substr(colon + 1));
        long long recv_bytes = 0, dummy = 0, sent_bytes = 0;

        iss >> recv_bytes;                          // 接收字节
        for (int i = 0; i < 7; ++i) iss >> dummy;   // 跳过 7 个字段
        iss >> sent_bytes;                          // 发送字节

        total_recv += recv_bytes;
        total_sent += sent_bytes;
    }

    out.sent = total_sent;
    out.recv = total_recv;
    return true;
}

// 通过两次采样计算速率，间隔秒数
NetSpeed get_net_speed(double interval_sec = 1.0)
{
    NetSpeed speed;
    NetBytes n1, n2;

    if (!read_net_bytes(n1)) return speed;

    std::this_thread::sleep_for(
        std::chrono::milliseconds(static_cast<int>(interval_sec * 1000)));

    if (!read_net_bytes(n2)) return speed;

    long long sent_diff = n2.sent - n1.sent;
    long long recv_diff = n2.recv - n1.recv;

    if (sent_diff < 0) sent_diff = 0;
    if (recv_diff < 0) recv_diff = 0;

    speed.sent_bps = sent_diff / interval_sec;
    speed.recv_bps = recv_diff / interval_sec;
    speed.sent_kbps = speed.sent_bps / 1024.0f;
    speed.recv_kbps = speed.recv_bps / 1024.0f;

    return speed;
}





//cpu信息获取
struct CpuTimes {
    long long idle = 0;
    long long total = 0;
};

bool read_cpu_times(CpuTimes & out)
{
    std::ifstream file("/proc/stat");
    if (!file.is_open()) return false;

    std::string line;
    std::getline(file, line);   // 第一行：cpu  user nice system idle iowait irq softirq steal ...

    std::istringstream iss(line);
    std::string label;
    iss >> label;               // 跳过 "cpu"

    long long user = 0, nice = 0, system = 0, idle = 0;
    long long iowait = 0, irq = 0, softirq = 0, steal = 0;
    iss >> user >> nice >> system >> idle
        >> iowait >> irq >> softirq >> steal;

    long long idle_all = idle + iowait;
    long long non_idle = user + nice + system + irq + softirq + steal;

    out.idle = idle_all;
    out.total = idle_all + non_idle;
    return true;
}

float get_cpu_percent()
{
    CpuTimes t1, t2;
    if (!read_cpu_times(t1)) return 0.0f;

    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    if (!read_cpu_times(t2)) return 0.0f;

    long long total_diff = t2.total - t1.total;
    long long idle_diff = t2.idle - t1.idle;

    if (total_diff <= 0) return 0.0f;

    float usage = 100.0f * (total_diff - idle_diff) / total_diff;
    if (usage < 0.0f) usage = 0.0f;
    if (usage > 100.0f) usage = 100.0f;
    return usage;
}


//主机名获取
std::string get_hostname()
{
    char buffer[256] = {0};
    if (gethostname(buffer, sizeof(buffer)) == 0) {
        return std::string(buffer);
    }
    return "unknown";
}
   
//编写节点和话题发布者
class Writenode : public rclcpp::Node
{
public:
     Writenode(const std::string & name): Node(name)
    {
        publisher=this->create_publisher<status_interfaces::msg::Massage>("test_topic",10);
        timer=this->create_wall_timer(std::chrono::seconds(4),std::bind(&Writenode::timer_callback,this));
        RCLCPP_INFO(this->get_logger(), "节点创建成功");
    }

private:rclcpp::Publisher<status_interfaces::msg::Massage>::SharedPtr publisher;
rclcpp::TimerBase::SharedPtr timer;

    void timer_callback()
    {     status_interfaces::msg::Massage msg;
        RCLCPP_INFO(get_logger(),"正在收集主机信息，准备发送");
        msg.hostname=get_hostname();
        msg.stamp=this->get_clock()->now();
        msg.cpu_percent= get_cpu_percent();
        MemInfo mem=get_memory_info();
        msg.memory_total=mem.total_mb;
        msg.memory_available=mem.available_mb;
        msg.memory_percent=float(100.0f * (msg.memory_total - msg.memory_available) / msg.memory_total);
        NetSpeed s=get_net_speed();
        msg.net_sent=s.sent_kbps;
        msg.net_recv=s.recv_kbps;
        publisher->publish(msg);
    }
};

int main(int argc, char ** argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<Writenode>("test_publish_node");
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
