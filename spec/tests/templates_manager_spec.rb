# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require 'spec_helper'
require_relative '../spec_helper'

RSpec.describe 'OpenStudio::Metadata::Mapping::TemplatesManager spec' do
  before(:all) do
    @templates_manager = OpenStudio::Metadata::Mapping::TemplatesManager.new
  end

  it 'Should read in templates' do
    expect(@templates_manager.send(:templates)).to_not be({})
  end

  it 'Should read in brick and haystack metadata definitions' do
    expect(@templates_manager.send(:haystack_repo)).to_not be nil
    expect(@templates_manager.send(:brick_repo)).to_not be nil
  end

  it 'Should have heatPump as a term in @haystack_repo' do
    haystack_repo = @templates_manager.send(:haystack_repo)
    phiot_vocab = @templates_manager.send(:phiot_vocab)
    expect(haystack_repo.has_subject?(phiot_vocab.heatPump)).to be true
  end

  it 'Should have AHU as a term in @brick_repo' do
    brick_repo = @templates_manager.send(:brick_repo)
    brick_vocab = @templates_manager.send(:brick_vocab)
    expect(brick_repo.has_subject?(brick_vocab['AHU'])).to be true
  end

  it "Should return four Haystack classes that are subclasses of an 'ahu'" do
    haystack_repo = @templates_manager.send(:haystack_repo)
    phiot_vocab = @templates_manager.send(:phiot_vocab)

    s = SPARQL::Client.new(haystack_repo)
    q = "SELECT ?e WHERE { ?e <#{RDF::RDFS.subClassOf}>* <#{phiot_vocab.ahu}> }"
    results = s.query(q)
    data = []
    results.each do |r|
      data << r['e'].to_s
    end
    data = data.to_set
    expect(data.size).to be 4
    expected = [
      phiot_vocab.ahu.to_s,
      phiot_vocab['doas'].to_s,
      phiot_vocab[:rtu].to_s,
      phiot_vocab.mau.to_s
    ]
    expected = expected.to_set
    expect(expected == data).to be true
  end

  it 'Should store templates as a Hash' do
    expect(@templates_manager.send(:templates)).to be_an_instance_of(Hash)
  end
end
