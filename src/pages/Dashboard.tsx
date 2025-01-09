import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { RadarChart } from '../components/RadarChart';
import { TrashIcon } from '@heroicons/react/24/outline';

export default function Dashboard() {
  const [radarCharts, setRadarCharts] = useState([{ id: 1, title: 'Assessment 1' }]);

  const addNewRadarChart = () => {
    const newId = radarCharts.length + 1;
    setRadarCharts([...radarCharts, { id: newId, title: `Assessment ${newId}` }]);
  };

  const removeRadarChart = (id: number) => {
    setRadarCharts(radarCharts.filter(chart => chart.id !== id));
  };

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
          <button
            onClick={addNewRadarChart}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Add New Assessment
          </button>
        </div>

        <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {radarCharts.map((chart) => (
            <div
              key={chart.id}
              className="relative bg-white rounded-lg shadow hover:shadow-lg transition-shadow duration-200"
            >
              <button
                onClick={() => removeRadarChart(chart.id)}
                className="absolute top-2 right-2 p-2 text-gray-400 hover:text-red-500 rounded-full hover:bg-gray-100 focus:outline-none"
                title="Remove assessment"
              >
                <TrashIcon className="h-5 w-5" />
              </button>
              <Link to={`/radar/${chart.id}`}>
                <div className="p-6">
                  <h2 className="text-xl font-medium text-gray-900 mb-4">{chart.title}</h2>
                  <div className="aspect-square">
                    <RadarChart 
                      data={{
                        labels: ['Category 1', 'Category 2', 'Category 3', 'Category 4', 'Category 5'],
                        datasets: [{
                          label: 'Score',
                          data: [4, 3, 5, 2, 4],
                          backgroundColor: 'rgba(99, 102, 241, 0.2)',
                          borderColor: 'rgba(99, 102, 241, 1)',
                          borderWidth: 2,
                        }]
                      }}
                    />
                  </div>
                </div>
              </Link>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}