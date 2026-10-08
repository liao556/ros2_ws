#include <functional>
#include <memory>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "status_interfaces/msg/massage.hpp"

class Writenode : public rclcpp::Node
{
public:
    explicit Writenode(const std::string & name)
    : Node(name)
    {
        // _1 必须写成 std::placeholders::_1，否则报 '_1' was not declared
        test_subscription = this->create_subscription<status_interfaces::msg::Massage>(
            "test_topic", 10,
            std::bind(&Writenode::test_callback, this, std::placeholders::_1));
        RCLCPP_INFO(this->get_logger(), "节点创建成功");
    }

private:
    rclcpp::Subscription<status_interfaces::msg::Massage>::SharedPtr test_subscription;

    void test_callback(status_interfaces::msg::Massage::SharedPtr msg)
    {RCLCPP_INFO_STREAM(this->get_logger(), "已经受到消息，主机"<< msg->hostname <<"，目前cpu使用率为"<<msg->cpu_percent<<"，内存还剩"<<msg->memory_available<<"MB。");
    }
};

int main(int argc, char ** argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<Writenode>("test_topic_node");
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
