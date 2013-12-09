#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>

#include <vector>
#include <fstream>
#include <string>
#include <sstream>
#include <iostream>
#pragma comment(lib, "cudart.lib")

using namespace std;
struct DataSet 
{
	int i;
	double d;
	int length;
	char s[200];

	__host__ __device__
	DataSet()
	{
		i = 0;
		d = 0;
		length = 0;
	}
	__host__ __device__
	DataSet(int j)
	{
		i = 0;
		d = 0;
		length = 0;		
	}
};
 __device__
DataSet operator+(const DataSet& a, const DataSet& b)
{
	DataSet r;
	r.d = a.d + b.d;
	r.i = a.i + b.i;
	memcpy(r.s, a.s, a.length);
	memcpy(r.s + a.length, b.s, b.length);
	r.length = a.length + b.length;
	r.s[r.length] = 0;
	return r;
}



vector<vector<DataSet>> readFile(const char* filename);
int main(int argc, char** argv)
{
	vector<vector<DataSet>> data = readFile("DapseviciusA_L4.txt");
	vector<DataSet> flatData;
	// Raktų masyvas nurodantis elementų indeksus
	vector<int> keys;
	// Duomenų masyvas perdaromas į vienmatį masyvą
	int keys_count = 0;
	for(int i = 0; i < data.size(); i++)
	{
		int j = 0;
		for(; j < data[i].size(); j++)
		{
			keys.emplace_back(j);
			flatData.emplace_back(data[i][j]);
		}
		if(keys_count < j)
		{
			keys_count = j;
		}
	}
	
    thrust::equal_to<int> binary_pred;
    thrust::plus<DataSet> binary_op;
	thrust::sort_by_key(keys.data(), keys.data() + keys.size(), flatData.data());

	thrust::host_vector<int> host_keys = keys;
	thrust::device_vector<int> device_keys = host_keys;

	thrust::host_vector<DataSet> host_values = flatData;
	thrust::device_vector<DataSet> device_values = host_values;

	thrust::device_vector<DataSet> output_values;
	output_values.reserve(flatData.size());
	thrust::device_vector<int> output_keys;
	output_keys.reserve(flatData.size());

	try
	{
		//p = thrust::reduce_by_key(keys.data(), keys.data() + keys.size(), flatData.data(), result_keys, result_values);
		auto p = thrust::reduce_by_key(device_keys.begin(), device_keys.end(), device_values.begin(), output_keys.begin(), output_values.begin(), binary_pred, binary_op);
	}
	catch(thrust::system_error &e)
	{
	// output an error message and exit
		std::cerr << "Error " << e.what() << std::endl;
		exit(-1);
	}

	thrust::host_vector<int> result_keys = output_keys;
	
	for(int i = 0; i < keys_count; i++)
	{
		cout << "Sudėjus elementus kurių indeksas yra " << output_keys[i] << " gauta:" << endl;
		DataSet d = output_values[i];
		printf("%3.3f, %3d, %s\n\n", d.d, d.i, d.s);
	}
	system("pause");
	return 0;
}

vector<vector<DataSet>> readFile(const char* filename)
{
	cout << "Pradiniai duomenys:" << endl;
	vector<vector<DataSet>> result;
	ifstream file(filename);
	if(file.good())
	{
		int count;
		file >> count;
		cout << "Masyvu kiekis:	" << count << endl;
		for(int i = 0; i < count; i++)
		{			
			vector<DataSet> temp;
			int itemCount;
			file >> itemCount;
			cout << "Masyvo elementu skaicius: " << itemCount << endl;
			cout << "Skaicius	sv. skaicius	eilute" << endl;
			for(int j = 0; j < itemCount; j++)
			{
				string word;
				DataSet current;
				file >> current.i >> current.d;
				getline(file, word);
				int length = word.length() > 20 ? 20 : word.length();
				memcpy(current.s, word.c_str()+1, length);
				current.s[19] = 0;
				current.length = length-1;
				temp.emplace_back(current);
				cout << current.d << "		" << current.i << "		" << current.s << endl;
			}
			cout << endl;
			result.emplace_back(temp);
		}
	}
	else
	{
		cout << "Negeras failas" << endl;
		system("pause");
		exit(-1);
	}
	return result;
}