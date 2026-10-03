from setuptools import find_packages, setup

package_name = 'receive_all'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    package_data={'': ['py.typed']},
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Liao Youming',
    maintainer_email='liaouiming@example.com',
    description='订阅话题 showing 并打印本机状态',
    license='TODO: License declaration',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            'receive_all_node=receive_all.subscibe:main',
        ],
    },
)
