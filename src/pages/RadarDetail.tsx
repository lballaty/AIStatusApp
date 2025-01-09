import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { RadarChart } from '../components/RadarChart';

export default function RadarDetail() {
  const { id } = useParams();
  const [status, setStatus] = useState('in-progress');

  const chartData = {
    labels: ['Category 1', 'Category 2', 'Category 3', 'Category 4', 'Category 5'],
    datasets: [{
      label: 'Current Score',
      data: [4, 3, 5, 2, 4],
      backgroundColor: 'rgba(99, 102, 241, 0.2)',
      borderColor: 'rgba(99, 102, 241, 1)',
      borderWidth: 2,
    }]
  };

  return (
    <div className="py-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-center mb-6">
            <h1 className="text-2xl font-semibold text-gray-900">Assessment {id}</h1>
            <div className="flex items-center space-x-4">
              <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                status === 'in-progress' ? 'bg-yellow-100 text-yellow-800' : 'bg-green-100 text-green-800'
              }`}>
                {status === 'in-progress' ? 'In Progress' : 'Completed'}
              </span>
              <button
                onClick={() => setStatus(status === 'in-progress' ? 'completed' : 'in-progress')}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Toggle Status
              </button>
            </div>
          </div>

          <div className="max-w-3xl mx-auto">
            <RadarChart data={chartData} />
          </div>

          <div className="mt-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">Notes</h2>
            <textarea
              className="w-full h-32 p-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Add notes about this assessment..."
            />
          </div>
        </div>
      </div>
    </div>
  );
}