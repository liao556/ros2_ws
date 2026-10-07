#include <memory>
#include <string>

#include <rclcpp/rclcpp.hpp>

class Writenode : public rclcpp::Node
{
public:
    explicit Writenode(const std::string & name)
    : Node(name)
    {
        RCLCPP_INFO(this->get_logger(), "这是一个C++节点");
    }
};

int main(int argc, char ** argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<Writenode>("make_node");
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
