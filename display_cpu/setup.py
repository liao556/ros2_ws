from setuptools import find_packages, setup

package_name = 'display_cpu'

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
    description='服务端：提供 check_cpu 服务',
    license='TODO: License declaration',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            'display_cpu_node=display_cpu.cpu:main',
        ],
    },
)
