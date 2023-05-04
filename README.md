# My Spark Fork
This a fork of Spark that does not cause a shuffle/repartition when doing a window partition on `spark_partition_id()`. This can allow for `zipWithIndex()` logic to be expressed in dataframes scalably without requiring RDD->Dataframe overhead, which can be relatively large.

## The basic problem I'm trying to solve:

When working in a traditional data warehouse environment where one common procedure is to map business keys to surrogate keys. I was trying to figure out how one would do that with dataframes just as a personal exercise, and got sort of fixated on this when I found there's not really a good way. Either it's not scalable (`row_number` without a partition), has what feels like unnecessary overhead ( `zipWithIndex` and `zipWithUniqueID` are fast and scalable, but going from rdd back to a dataframe is relatively slow), has the potential for large gaps except under relatively specific circumstances ( `monotonically_increasing_id` ), or isn't future-proof ( you can use Pandas udfs to do it without shuffling, but even `Iterator[Series]->Iterator[Series]` functions purposefully don't guarantee the extent of data you get even though right now it's the all the data for a single partition).

So one thing I tried was to emulate `zipWithUniqueID` in dataframes to remove the rdd->dataframe overhead like:
> `arbitraryWindow = Window.partitionBy(F.spark_partition_id()).orderBy(F.lit(None))`
> `keys = businessKeyRows.withColumn('SurrogateKey',(F.row_number().over(arbitraryWindow)-1)*F.lit(hashedRows.rdd.getNumPartitions())+F.spark_partition_id())`

But this didn't work since the window function repartitioned and coalesced them into a smaller number of partitions, but still calculated `row_number()` over the original partitions. The added `spark_partition_id()` then returned the new (fewer) partition ids, causing duplicates. So not only did it reduce performance by doing an unnecessary repartition and actually decreasing scalability by reducing the partitions, it caused it to be functionally wrong, too. After my change, it's correct and fast.  (Of course, even with my fix one has to be careful. If I did select with another window function, that could still cause the added `spark_partition_id` to use the wrong partition again due to how the query planner would order things).

# Apache Spark

Spark is a unified analytics engine for large-scale data processing. It provides
high-level APIs in Scala, Java, Python, and R, and an optimized engine that
supports general computation graphs for data analysis. It also supports a
rich set of higher-level tools including Spark SQL for SQL and DataFrames,
pandas API on Spark for pandas workloads, MLlib for machine learning, GraphX for graph processing,
and Structured Streaming for stream processing.

<https://spark.apache.org/>

[![GitHub Actions Build](https://github.com/apache/spark/actions/workflows/build_main.yml/badge.svg)](https://github.com/apache/spark/actions/workflows/build_main.yml)
[![AppVeyor Build](https://img.shields.io/appveyor/ci/ApacheSoftwareFoundation/spark/master.svg?style=plastic&logo=appveyor)](https://ci.appveyor.com/project/ApacheSoftwareFoundation/spark)
[![PySpark Coverage](https://codecov.io/gh/apache/spark/branch/master/graph/badge.svg)](https://codecov.io/gh/apache/spark)
[![PyPI Downloads](https://static.pepy.tech/personalized-badge/pyspark?period=month&units=international_system&left_color=black&right_color=orange&left_text=PyPI%20downloads)](https://pypi.org/project/pyspark/)


## Online Documentation

You can find the latest Spark documentation, including a programming
guide, on the [project web page](https://spark.apache.org/documentation.html).
This README file only contains basic setup instructions.

## Building Spark

Spark is built using [Apache Maven](https://maven.apache.org/).
To build Spark and its example programs, run:

```bash
./build/mvn -DskipTests clean package
```

(You do not need to do this if you downloaded a pre-built package.)

More detailed documentation is available from the project site, at
["Building Spark"](https://spark.apache.org/docs/latest/building-spark.html).

For general development tips, including info on developing Spark using an IDE, see ["Useful Developer Tools"](https://spark.apache.org/developer-tools.html).

## Interactive Scala Shell

The easiest way to start using Spark is through the Scala shell:

```bash
./bin/spark-shell
```

Try the following command, which should return 1,000,000,000:

```scala
scala> spark.range(1000 * 1000 * 1000).count()
```

## Interactive Python Shell

Alternatively, if you prefer Python, you can use the Python shell:

```bash
./bin/pyspark
```

And run the following command, which should also return 1,000,000,000:

```python
>>> spark.range(1000 * 1000 * 1000).count()
```

## Example Programs

Spark also comes with several sample programs in the `examples` directory.
To run one of them, use `./bin/run-example <class> [params]`. For example:

```bash
./bin/run-example SparkPi
```

will run the Pi example locally.

You can set the MASTER environment variable when running examples to submit
examples to a cluster. This can be a mesos:// or spark:// URL,
"yarn" to run on YARN, and "local" to run
locally with one thread, or "local[N]" to run locally with N threads. You
can also use an abbreviated class name if the class is in the `examples`
package. For instance:

```bash
MASTER=spark://host:7077 ./bin/run-example SparkPi
```

Many of the example programs print usage help if no params are given.

## Running Tests

Testing first requires [building Spark](#building-spark). Once Spark is built, tests
can be run using:

```bash
./dev/run-tests
```

Please see the guidance on how to
[run tests for a module, or individual tests](https://spark.apache.org/developer-tools.html#individual-tests).

There is also a Kubernetes integration test, see resource-managers/kubernetes/integration-tests/README.md

## A Note About Hadoop Versions

Spark uses the Hadoop core library to talk to HDFS and other Hadoop-supported
storage systems. Because the protocols have changed in different versions of
Hadoop, you must build Spark against the same version that your cluster runs.

Please refer to the build documentation at
["Specifying the Hadoop Version and Enabling YARN"](https://spark.apache.org/docs/latest/building-spark.html#specifying-the-hadoop-version-and-enabling-yarn)
for detailed guidance on building for a particular distribution of Hadoop, including
building for particular Hive and Hive Thriftserver distributions.

## Configuration

Please refer to the [Configuration Guide](https://spark.apache.org/docs/latest/configuration.html)
in the online documentation for an overview on how to configure Spark.

## Contributing

Please review the [Contribution to Spark guide](https://spark.apache.org/contributing.html)
for information on how to get started contributing to the project.
